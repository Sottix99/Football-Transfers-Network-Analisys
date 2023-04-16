# Football Transfers Network Analisys
![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

This Repository refers to the Final Project of the course Data Driven Models for Complex Systems (DDMCS) at University Sapienza of Rome 2022/2023.

# Abstract

![My Imaged](Imgs/sistemare.png)

# Dataset

![My Imaged](Imgs/cover1.png)

The data comes from Kaggle, scraped from Transfer Markt. The datasets regards all the transfer operation in the major 7 European leagues from the 1992/1993 season to
the 2021/2022 season. The raw data were extremely dirty so a massive and detailed cleaning operation was necessary.

# Cleaning procedures

1. Scrape data from Transfer Markt to build two types of dictionaries:
 - one that maps every team name for every season its long name to the short one. (ex: "Juventus FC" : "Juventus").
 - one that maps each club not in the 7 top leagues in its continent/country. (ex: "Santos" : "South America").
 
2. Delete all the "out" and "End of loan" operations to avoid duplicate transactions.

3. Check and correct some typos in original data.

![My Imaged](Imgs/Data_and_Cleaning_procedure.png)
