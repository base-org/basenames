import math
import matplotlib.pyplot as plt

PRECISION = 10 ** 18
SECONDS_PER_DAY = 86400

def decayed_premium(start_premium, elapsed_seconds, seconds_in_period, per_period_decay_percent_wad):
    ratio = elapsed_seconds / seconds_in_period

    percent_wad_remaining_per_period = (PRECISION - per_period_decay_percent_wad) / PRECISION
    multiplier = (percent_wad_remaining_per_period ** ratio) 

    price = (start_premium * multiplier) 
    return price

def calculate_prices(start_premium, end_value, num_days, seconds_in_period, per_period_decay_percent_wad):
    elapsed_times = []
    prices = []

    for day in range(num_days):
        for i in range(10):
            elapsed_time = (day + i / 10) * SECONDS_PER_DAY

            premium = decayed_premium(start_premium, elapsed_time, seconds_in_period, per_period_decay_percent_wad)

            price = max(premium, end_value) / PRECISION
            elapsed_times.append(day + i / 10)
            prices.append(price)

    return elapsed_times, prices

start = int(input("Input a value for the start premium: "))
total = int(input("How many days would it take for the price to reach its end value: "))
num = int(input("Input a value for the number of days over which the price should decay: "))

start_premium = start * (10 ** 18)
total_days = total
seconds_in_period = SECONDS_PER_DAY
per_period_decay_percent = 50

per_period_decay_percent_wad = int(per_period_decay_percent * PRECISION / 100)
end_value = start_premium >> total_days

num_days = num  

elapsed_times, prices = calculate_prices(start_premium, end_value, num_days, seconds_in_period, per_period_decay_percent_wad)
plt.figure(figsize=(start, num))
plt.plot(elapsed_times, prices, marker='o')
plt.xlabel('Elapsed Time (days)')
plt.ylabel('Premium Price')
plt.title('Pricing Chart')
plt.grid(True)
plt.xticks(range(num_days + 1))
plt.show()