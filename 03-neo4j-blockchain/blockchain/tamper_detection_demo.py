"""Minimal educational blockchain: 3 bank replicas, tampering, detection, repair.

My own compact, non-interactive re-implementation of the scenario tested in the
lab (the original interactive notebook was provided by the instructor).

Two attackers are compared:
  * hacker  - changes one block and recomputes ONLY its hash
              -> the next block still points to the old hash -> chain invalid
  * insider - changes one block and recomputes ALL following hashes
              -> chain is internally valid; only comparison with other
                 replicas (majority) reveals the change

Run:  python tamper_detection_demo.py
"""
from __future__ import annotations

import hashlib
import json
from copy import deepcopy
from dataclasses import dataclass, field


@dataclass
class Block:
    index: int
    transactions: list[str]
    previous_hash: str
    timestamp: str = "2026-11-14 11:00:00"
    hash: str = field(init=False)

    def __post_init__(self) -> None:
        self.hash = self.calculate_hash()

    def calculate_hash(self) -> str:
        payload = json.dumps(
            {
                "index": self.index,
                "timestamp": self.timestamp,
                "transactions": self.transactions,
                "previous_hash": self.previous_hash,
            },
            sort_keys=True,
        )
        return hashlib.sha256(payload.encode()).hexdigest()


class Blockchain:
    def __init__(self, name: str) -> None:
        self.name = name
        self.chain = [Block(0, ["Genesis block"], "0")]

    def is_valid(self) -> bool:
        """Local integrity check: every hash correct and every link intact."""
        for i, block in enumerate(self.chain):
            if block.hash != block.calculate_hash():
                return False
            if i > 0 and block.previous_hash != self.chain[i - 1].hash:
                return False
        return True

    def fingerprint(self) -> tuple[str, ...]:
        return tuple(b.hash for b in self.chain)


def majority_chain(network: list[Blockchain]) -> list[Block] | None:
    """Identical, locally valid chain held by at least floor(n/2)+1 replicas."""
    groups: dict[tuple[str, ...], list[Blockchain]] = {}
    for bank in network:
        if bank.is_valid():
            groups.setdefault(bank.fingerprint(), []).append(bank)
    quorum = len(network) // 2 + 1
    for banks in groups.values():
        if len(banks) >= quorum:
            return banks[0].chain
    return None


def print_state(title: str, network: list[Blockchain]) -> None:
    print(f"\n=== {title} ===")
    for bank in network:
        print(f"{bank.name}  valid={bank.is_valid()}")
        for b in bank.chain:
            print(f"   block {b.index}: {b.transactions[0]:<42} "
                  f"h={b.hash[:8]} prev={b.previous_hash[:8]}")


def build_network() -> list[Blockchain]:
    network = [Blockchain("Bank A"), Blockchain("Bank B"), Blockchain("Bank C")]
    txs = [
        "Alicja (A) -> Bartek (B): 50.00 PLN",
        "Bartek (B) -> Celina (C): 25.00 PLN",
        "Celina (C) -> Alicja (A): 12.50 PLN",
    ]
    for tx in txs:                       # broadcast: every bank gets the same block
        last = network[0].chain[-1]
        block = Block(len(network[0].chain), [tx], last.hash)
        for bank in network:
            bank.chain.append(deepcopy(block))
    return network


def tamper(bank: Blockchain, block_index: int, new_tx: str, recompute_following: bool) -> None:
    target = bank.chain[block_index]
    target.transactions = [new_tx]
    target.hash = target.calculate_hash()
    if recompute_following:              # insider hides the change
        for j in range(block_index + 1, len(bank.chain)):
            bank.chain[j].previous_hash = bank.chain[j - 1].hash
            bank.chain[j].hash = bank.chain[j].calculate_hash()


def diagnose_and_repair(network: list[Blockchain], snapshot: list[Block], method: str) -> None:
    ref = majority_chain(network)
    ref_fp = tuple(b.hash for b in ref) if ref else None
    print("\n--- diagnostics (before repair) ---")
    for bank in network:
        agrees = bank.fingerprint() == ref_fp
        first_bad = next((i for i, b in enumerate(bank.chain) if ref and b.hash != ref[i].hash), None)
        print(f"{bank.name}: is_valid={bank.is_valid()!s:<5} agrees_with_majority={agrees!s:<5} "
              f"first_inconsistent_block={first_bad}")

    source = ref if (method == "majority" and ref is not None) else snapshot
    repaired = [b.name for b in network if b.fingerprint() != tuple(x.hash for x in source)]
    for bank in network:
        bank.chain = deepcopy(source)
    print(f"repair method: {method} -> repaired: {repaired}")


def run(attacker: str, block_index: int, new_tx: str, victim: str, method: str) -> None:
    print("\n" + "#" * 78 + f"\n# Scenario: {attacker.upper()}\n" + "#" * 78)
    network = build_network()
    snapshot = deepcopy(network[0].chain)          # trusted copy from before the attack
    bank = next(b for b in network if b.name == victim)
    tamper(bank, block_index, new_tx, recompute_following=(attacker == "insider"))
    print_state("AFTER TAMPERING", network)
    diagnose_and_repair(network, snapshot, method)
    print_state("FINAL STATE", network)


if __name__ == "__main__":
    # Same inputs as in the lab runs
    run("hacker",  block_index=2, new_tx="Bartek (B) -> Celina (C): 100.00 PLN",
        victim="Bank B", method="majority")
    run("insider", block_index=1, new_tx="Alicja (A) -> Bartek (B): 500.00 PLN",
        victim="Bank B", method="snapshot")
