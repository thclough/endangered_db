#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan  2 15:23:49 2023

@author: Tighe_Clough
"""

from dash import Dash, dcc, html, Input, Output
import pandas as pd
import numpy as np
import plotly.express as px

## General visualization df
root3 = "https://github.com/thclough/endangered_db/blob/main/query_output_and_visualizations/general/"
year_spec_df = pd.read_csv(root3 + "yearly_specimen_trade.csv", keep_default_na=False)

# give Kosovo a continent
kv_idx = year_spec_df[year_spec_df.country_name=="Kosovo"].index
year_spec_df.loc[kv_idx,"continent_code"] = "EU"

# get rid of "world", only want on a per country basis
country_year_spec_df = year_spec_df[year_spec_df.country_name != "World"].sort_values(["year"])

# continents in first frame are not included, will add missing continent placeholders for plotly
missing_conts = set(country_year_spec_df.continent_code.unique()) - set(country_year_spec_df[country_year_spec_df["year"]==1975].continent_code.unique())

# add missing continent dumy entries for plotly
for cont in missing_conts:
    row = [[1975, "Placeholder", "PH", cont]+[np.nan]*6]
    country_year_spec_df = country_year_spec_df.append(pd.DataFrame(row , columns=country_year_spec_df.columns), ignore_index=True)

country_year_spec_df.sort_values(by=["year","continent_code"], inplace=True)

# create dictionary to map code to names for easy readability
code_name_dict = {"AF":"Africa", "AS":"Asia", "EU":"Europe", "NA":"North America", "OC":"Oceania", "SA":"South America"}

# create button list for selection of continent
# ex. [True, True, False, False] will display the fist two traces
# scatter data and corresponding OLS trend line are treated as separate traces, but ordered next to each other
# traces appear in the order the color group appears in the dataframe 
# ex. Africa is listed first in the dataframe so its scatter trace appears first and then its line trace
# to display both traces would need to set visibility list to [True, True, False,...,False]
unique_conts = country_year_spec_df.continent_code.unique()
num_conts = len(unique_conts)

# intialize button list with selection for all continents 
cont_button_list = [{"label":"All", "method":"update", "args": [{"visible":[True]*num_conts*2}]}]

for idx,cont_code in enumerate(unique_conts):
    
    # initialzie the dictionary
    button_dict = dict()
    
    # find name of the continent
    name = code_name_dict[cont_code]
    
    # create trace visibility list and citionary for plotly
    vis_list = [False] * num_conts*2
    true_idx_start = idx*2
    
    # set true for both scatter and line trace
    vis_list[true_idx_start:true_idx_start+2] = [True,True]
    args_dict = {"visible":vis_list}
    
    # set dictionary values
    button_dict["label"] = f"{cont_code} ({name})"
    button_dict["method"] = "update"
    button_dict["args"] = [args_dict]
    
    # append dictionary to button list
    cont_button_list.append(button_dict)

fig3 = px.scatter(country_year_spec_df, x="gdp_per_capita_yma", y="specimen_imports_per_100k_log",
                 animation_frame="year", animation_group="country_name", color="continent_code",
                 range_x=[-1000,200000], range_y=[-10,20],
                 height=600,
                 hover_name="country_name", hover_data=["total_imported", "total_pop"],
                 size_max=100, opacity=.8, trendline="ols",
                 title="Total Imported CITES Specimens on a per 100k Population Basis vs Income per Capita since 1975",
                 labels={
                     "specimen_imports_per_100k_log": "Total Specimens Imported (per 100K population basis, log scale)",
                     "gdp_per_capita_yma": "GDP per Capita, Yearly Moving Average +/- 5 Years",
                     "continent_code":"Continent Code",
                     "total_imported": "Total Specimens Imported",
                     "total_pop": "Population"})



fig3.layout["updatemenus"] = [
        dict(
            buttons=list(cont_button_list),
            direction="down",
            pad={"r": 10, "t": 10},
            showactive=True,
            x=1.005,
            xanchor="right",
            y=1.02,
            yanchor="top"
        ),
        # animation buttons
        {'buttons': [{'args': [None, {'frame': {'duration':
                                                      500, 'redraw': False},
                                                      'mode': 'immediate',
                                                      'fromcurrent': True,
                                                      'transition': {'duration':
                                                      500, 'easing': 'linear'}}],
                                             'label': '&#9654;',
                                             'method': 'animate'},
                                            {'args': [[None], {'frame':
                                                      {'duration': 0, 'redraw':
                                                      False}, 'mode': 'immediate',
                                                      'fromcurrent': True,
                                                      'transition': {'duration': 0,
                                                      'easing': 'linear'}}],
                                             'label': '&#9724;',
                                             'method': 'animate'}],
                                'direction': 'left',
                                'pad': {'r': 10, 't': 70},
                                'showactive': False,
                                'type': 'buttons',
                                'x': 0,
                                'xanchor': 'left',
                                'y': 0,
                                'yanchor': 'top'}
    ]

fig3.layout["annotations"]=[
        dict(text="Select Continent:", showarrow=False,
        x=1, xref="paper", y=1.1, yref="paper")
    ]

fig3.update_yaxes(automargin='left+top')


app = Dash(__name__)
server = app.server

app.layout = html.Div([
    dcc.Graph(id="my_scatter", figure=fig3)
])



if __name__ == "__main__":
    app.run_server(debug=False)


