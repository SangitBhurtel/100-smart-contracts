const { ethers } = require("ethers");

// ---- Config ----
const NUM_ADDRESSES = 10;
const MIN_AMOUNT = ethers.parseUnits("10", 18);
const MAX_AMOUNT = ethers.parseUnits("1000", 18);

// ---- Step 1: generate random airdrop list ----
function randomAmount() {
  const range = MAX_AMOUNT - MIN_AMOUNT;
  const rand = BigInt(Math.floor(Math.random() * Number(range / 1000000000000000000n))) * 1000000000000000000n;
  return MIN_AMOUNT + rand;
}

const airdropList = [];
for (let i = 0; i < NUM_ADDRESSES; i++) {
  const wallet = ethers.Wallet.createRandom();
  airdropList.push({ address: wallet.address, amount: randomAmount() });
}

// ---- Step 2: leaf hashing (matches contract's double-hash pattern) ----
// leaf = keccak256(keccak256(abi.encode(address, amount)))
// The double hash guards against second-preimage attacks where a crafted
// internal node could be replayed as a fake leaf.
function hashLeaf(address, amount) {
  const inner = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(["address", "uint256"], [address, amount])
  );
  return ethers.keccak256(inner);
}

// ---- Step 3: sorted-pair combine (order-independent, matches contract) ----
function combine(a, b) {
  const [lo, hi] = BigInt(a) < BigInt(b) ? [a, b] : [b, a];
  return ethers.keccak256(ethers.concat([lo, hi]));
}

// ---- Step 4: build tree, level by level, keeping every level for proof lookup ----
function buildTree(leaves) {
  const levels = [leaves];
  let current = leaves;
  while (current.length > 1) {
    const next = [];
    for (let i = 0; i < current.length; i += 2) {
      if (i + 1 < current.length) {
        next.push(combine(current[i], current[i + 1]));
      } else {
        // odd node out — carries up unchanged to the next level
        next.push(current[i]);
      }
    }
    levels.push(next);
    current = next;
  }
  return levels; // levels[0] = leaves, levels[last] = [root]
}

// ---- Step 5: derive proof for a given leaf index by walking sibling indices up ----
function getProof(levels, leafIndex) {
  const proof = [];
  let index = leafIndex;
  for (let level = 0; level < levels.length - 1; level++) {
    const currentLevel = levels[level];
    const isRightNode = index % 2 === 1;
    const siblingIndex = isRightNode ? index - 1 : index + 1;
    if (siblingIndex < currentLevel.length) {
      proof.push(currentLevel[siblingIndex]);
    }
    index = Math.floor(index / 2);
  }
  return proof;
}

// ---- Run it ----
const leaves = airdropList.map((entry) => hashLeaf(entry.address, entry.amount));
const levels = buildTree(leaves);
const root = levels[levels.length - 1][0];

console.log("=== MERKLE AIRDROP GENERATOR ===\n");
console.log(`Addresses: ${NUM_ADDRESSES}`);
console.log(`MERKLE ROOT (pass this to the constructor):\n${root}\n`);

console.log("=== Sample entries (first 3, for manual testing) ===");
for (let i = 0; i < 3; i++) {
  const proof = getProof(levels, i);
  console.log(`\nAddress:  ${airdropList[i].address}`);
  console.log(`Amount:   ${airdropList[i].amount.toString()} (${ethers.formatUnits(airdropList[i].amount, 18)} tokens)`);
  console.log(`Leaf:     ${leaves[i]}`);
  console.log(`Proof:    [${proof.join(", ")}]`);
}

// ---- Self-verify every single proof against the root, contract-style ----
function verify(proof, leaf, root) {
  let computed = leaf;
  for (const sibling of proof) {
    computed = combine(computed, sibling);
  }
  return computed === root;
}

let allValid = true;
for (let i = 0; i < NUM_ADDRESSES; i++) {
  const proof = getProof(levels, i);
  if (!verify(proof, leaves[i], root)) {
    allValid = false;
    console.log(`\n!! Proof failed for index ${i} (${airdropList[i].address})`);
  }
}
console.log(`\nSelf-check: all ${NUM_ADDRESSES} proofs verify against the root? ${allValid}`);

// ---- Dump full list + proofs to JSON for later use ----
const fs = require("fs");
const path = require("path");
const output = {
  root,
  claims: airdropList.map((entry, i) => ({
    address: entry.address,
    amount: entry.amount.toString(),
    proof: getProof(levels, i),
  })),
};
const outPath = path.join(__dirname, "..", "data", "airdrop-data.json");
fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
console.log(`\nFull data (root + every address/amount/proof) written to ${path.relative(process.cwd(), outPath)}`);