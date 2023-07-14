
import pandas as pd

zipcodes=pd.read_csv('path_example.csv')

# load the income data
# Source: https://www.psc.isr.umich.edu/dis/census/HCT012.csv
print(f"Loading income data...",end='',flush=True)
income = pandas.read_csv("income_CA.csv",index_col="zipcode")
print("ok",flush=True)

# add the income data
# TODO: add other states
print(f"Adding income data...",end='',flush=True)
zipcodes = zipcodes.join(income,how="inner",on="zipcode",sort=True)
print("ok",flush=True)

zipcodes.to_csv('C:\Users\isabe\OneDrive\Documents\SLAC Summer Internship '23\GitHub\resilience\incomes.csv')

