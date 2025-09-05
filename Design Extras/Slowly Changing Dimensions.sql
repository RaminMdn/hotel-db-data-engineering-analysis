-- Implementing Slowly Changing Dimensions (SCD Type 2):

/*
If we want to historize guest data, for instance when their details change, we might implement slowly changing dimensions. 

We need to build a guest dimension table for historical analysis in a hotel’s data warehouse. 
Guest details (like City or Phone) may change over time, and we must retain the history of changes. 
*/