import math
import matplotlib.pyplot as plt

PRECISION = 10 ** 18
SECONDS_PER_HOUR = 2600
PER_PERIOD_DECAY_PERCENT = 50
DAY_FRACTION = 8

def decayed_premium(start_premium, elapsed_seconds, seconds_in_period, per_period_decay_percent_wad):
    ratio = elapsed_seconds / seconds_in_period

    percent_wad_remaining_per_period = (PRECISION - per_period_decay_percent_wad) / PRECISION
    multiplier = (percent_wad_remaining_per_period ** ratio) 

    price = (start_premium * multiplier) 
    return price

def calculate_prices(base_price, start_premium, end_value, num_days, seconds_in_period, per_period_decay_percent_wad):
    elapsed_times = []
    prices = []

    for hour in range(num_days * 24 + 1):
        for i in range(10):
            elapsed_time = (hour + i / 10) * SECONDS_PER_HOUR

            premium = decayed_premium(start_premium, elapsed_time, seconds_in_period, per_period_decay_percent_wad)

            price = (((premium - end_value) / PRECISION)) + base_price
            elapsed_times.append(hour + i / 10)
            prices.append(price)

    return elapsed_times, prices

start = int(input("Input a value for the start premium (ETH): "))
num_days = int(input("Input a value for the number of days over which the price should decay: "))
halflife = float(input("Input the number of hours in the halflife: "))
base = float(input("Input the base price (ETH) of the name: "))

start_premium = start * (10 ** 18)
seconds_in_period = SECONDS_PER_HOUR * halflife
num_hours = num_days * 24

per_period_decay_percent_wad = int(PER_PERIOD_DECAY_PERCENT * PRECISION / 100)
end_value = start_premium >> int(num_days * (24 / halflife))

print(end_value)

elapsed_times, prices = calculate_prices(base, start_premium, end_value, num_days, seconds_in_period, per_period_decay_percent_wad)

data = zip(elapsed_times, prices)

with open("1.5hr1day.csv", "a") as f:
    for line in data:
        f.write(str(line[0]) + "," + str(line[1]) + "\n")

plt.figure(figsize=(start, num_hours))
plt.plot(elapsed_times, prices, marker='o')
plt.xlabel('Elapsed Time (hours)')
plt.ylabel('Premium Price')
plt.title('Pricing Chart')
plt.grid(True)
plt.xticks(range(num_days*DAY_FRACTION*3 + 1))
plt.show()