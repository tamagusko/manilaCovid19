"""
Processes data from Google and Apple
Author:  Tiago Tamagusko <tamagusko@gmail.com>
Version: 0.2 (2020-10-21)
License: CC-BY-NC-ND-4.0
"""
import json
import urllib.request
import datetime

import pandas as pd

CURRENT_TIME: str = datetime.datetime.today().strftime("%y-%m-%d_%H:%M")


def drop_df_col(df, *columns_drop):
    """Drop dataframe columns
    in:  dataframe, % driving, % transit, % walking
    out: mobility index
    """
    df.drop(df.columns[[columns_drop]], axis=1, inplace=True)
    return df


def replace_df_col(df, old, new):
    """Replace dataframe columns
    in:  dataframe old columns and new columns
    out: dataframe with new columns
    """
    df.columns = df.columns.str.replace(old, new)
    return df


def prepare_google_data():
    """Prepare google data"""
    raw_google_data = (
        "https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv"
    )

    # adapted for big data using chuck
    data_iterator = pd.read_csv(
        raw_google_data,
        index_col="date",
        parse_dates=[4],
        low_memory=False,
        chunksize=10000,
        usecols=[
            "country_region",
            "metro_area",
            "date",
            "retail_and_recreation_percent_change_from_baseline",
            "grocery_and_pharmacy_percent_change_from_baseline",
            "parks_percent_change_from_baseline",
            "transit_stations_percent_change_from_baseline",
            "workplaces_percent_change_from_baseline",
            "residential_percent_change_from_baseline",
        ],
        infer_datetime_format=True,
    )

    chunk_list = []

    # Each chunk is in dataframe format
    for data_chunk in data_iterator:
        data_chunk = data_chunk[data_chunk['country_region'] == 'Philippines']
        data_chunk = data_chunk[data_chunk['metro_area']
                                == 'Manila Metropolitan Area']
        chunk_list.append(data_chunk)
    # concat all chucks
    df = pd.concat(chunk_list)

    replace_df_col(df, r"_percent_change_from_baseline", "")
    replace_df_col(df, r"_", " ")
    df = drop_df_col(df, 0, 1)
    df.to_csv("data/google_data_processed.csv")
   

def prepare_apple_data():
    """Get link of dataset from apple mobility reports using json API"""
    json_url = (
        "https://covid19-static.cdn-apple.com/covid19-mobility-data"
        "/current/v3/index.json "
    )
    with urllib.request.urlopen(json_url) as url:
        json_data = json.loads(url.read().decode())
    apple_dataset = (
        "https://covid19-static.cdn-apple.com"
        + json_data["basePath"]
        + json_data["regions"]["en-us"]["csvPath"]
    )
    # save data into a df
    df = pd.read_csv(apple_dataset, low_memory=False)
    df = df.drop(columns=["alternative_name"])
    df["country"] = df.apply(
        lambda x: x["region"] if x["geo_type"] == "country/region" else x["country"],
        axis=1,
    )

    df = df[df.geo_type != "county"]
    df["sub-region"] = df.apply(
        lambda x: "Total"
        if x["geo_type"] == "country/region"
        else (x["region"] if x["geo_type"] == "sub-region" else x["sub-region"]),
        axis=1,
    )
    df["subregion_and_city"] = df.apply(
        lambda x: "Total" if x["geo_type"] == "country/region" else x["region"], axis=1
    )
    df = df.drop(columns=["region"])
    df["sub-region"] = df["sub-region"].fillna(df["subregion_and_city"])

    df = df.melt(
        id_vars=[
            "geo_type",
            "subregion_and_city",
            "sub-region",
            "transportation_type",
            "country",
        ],
        var_name="date",
    )
    df["value"] = df["value"] - 100

    df = df.pivot_table(
        index=["geo_type", "subregion_and_city",
               "sub-region", "date", "country"],
        columns="transportation_type",
    ).reset_index()
    df.columns = [t + (v if v != "value" else "") for v, t in df.columns]
    df = df.loc[
        :,
        [
            "country",
            "sub-region",
            "subregion_and_city",
            "geo_type",
            "date",
            "driving",
            "transit",
            "walking",
        ],
    ]
    df = df.sort_values(
        by=["country", "sub-region", "subregion_and_city", "date"]
    ).reset_index(drop=True)
    df.set_index("date", inplace=True)
    # Filter for country and sub-region
    df = df[df["country"] == 'Philippines']
    df = df[df["sub-region"] == 'Manila']
    df = drop_df_col(df, 0, 1, 2, 3)
    df.to_csv("data/apple_data_processed.csv")
    

prepare_google_data()
prepare_apple_data()
