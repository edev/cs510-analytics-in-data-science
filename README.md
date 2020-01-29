# Soup Kitchen Website Dashboard

Team Chart Soup: Dylan Laufenberg \
CS 510 - Analytics in Data Science \
Portland State University \
Winter 2020

## Project Goal

I will develop a set of roughly 3-5 data visualizations over the Bounty data set using Highcharts.

## Project Summary

Two terms ago, I worked with Terry Tower to explore the [Sharing God’s Bounty](https://sharinggodsbounty.com) soup kitchen’s website database. I presented our work to Bounty’s Fearless Leader, and we developed a list of visualizations that he would like to see added to the website’s administrative dashboard. With this project, I aim to develop prototypes of these data visualizations using technologies that will integrate well into the website’s existing codebase and are free for non-profit use. These visualizations, once integrated into the website, will serve two purposes. First, they will allow leaders to visualize and analyze our meal service over time, e.g. to predict how many guests we might see any given week or to analyze trends over time. Second, these visualizations will allow leaders to assess their readiness for the annual Christmas event in terms of volunteer and donation needs vs. sign-ups. These visualizations represent Bounty’s first ever analysis of historical data, since the website’s database is Bounty’s first and only source of historical data.

I will develop the visualizations primarily using [Highcharts](https://highcharts.com), supplementing with [D3](https://d3js.org) or plain HTML if needed or appropriate. I will either adapt the existing [SQLite3](https://sqlite.org) database to this use case (e.g. by adding metadata about Christmas event dates each year) or use the [CouchDB](https://couchdb.apache.org) database from my term project last term, which can already answer the questions I will pose of the data. I will most likely run queries through [Sinatra](http://sinatrarb.com), but if time permits, I might develop a [Ruby on Rails](https://rubyonrails.org) prototype, since the website uses Rails. The final deliverable will not be a fully formed administrative dashboard but will instead be a set of (hopefully interactive) visualizations ready to be integrated into a future dashboard.

## Team Roles

As I am working solo, I will perform all work for this project.

## Task List

For those with permission (e.g. Kristin and Hisham), the prescribed task list is available [here](https://docs.google.com/spreadsheets/d/1CUl_LhUJIpeTCCYUsAmj-yaHKzr6QwEefVFgDASnyNk/).
