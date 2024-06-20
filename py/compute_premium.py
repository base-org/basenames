import sys
from eth_abi import encode

PRECISION = 10 ** 18
SECONDS_PER_DAY = 86400
PER_PERIOD_DECAY_PERCENT = 50
PER_PERIOD_DECAY_PERCENT_WAD = int(PER_PERIOD_DECAY_PERCENT * PRECISION / 100)

class DecayedPriceCalculator:
    @staticmethod
    def decayed_premium(start_premium, elapsed_seconds):
        ratio = elapsed_seconds / SECONDS_PER_DAY
        percent_wad_remaining_per_period = (PRECISION - PER_PERIOD_DECAY_PERCENT_WAD) / PRECISION
        multiplier = (percent_wad_remaining_per_period ** ratio)
        price = (start_premium * multiplier)
        return int(price) 

    @classmethod
    def calculate_from_cli(cls):
        if len(sys.argv) != 3:
            print("Usage: python3 price.py <start_premium> <elapsed_seconds>")
            sys.exit(1)
        
        start_premium = int(sys.argv[1])
        elapsed_seconds = int(sys.argv[2])
        
        result = cls.decayed_premium(start_premium, elapsed_seconds)
        enc = encode(['uint256'], [result])
        print("0x" + enc.hex())

if __name__ == "__main__":
    DecayedPriceCalculator.calculate_from_cli()