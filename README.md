ml-enrich
=========

Content enrichment with xquery on marklogic

This was originally coded by Stewart Shelline 
Then later was enhanced by William Sawyer (https://github.com/williammsawyer). 
So some of the concepts that they thought up are still part of this code. 
It has since been recoded and anything that was specific to application it was made for has been removed. 

The endpoint.xqy file shows an example of setting up a rest end point for enriching your content.
The example.xqy file shows an example of running the enriching function on some content.

The configuration folder has some example entities for enriching. 
The code is expecting the entities to be with in this path: "/enrich/configuration/"

The related.xqy files requires content to be saved into the database after it has been enriched.
It will look at the content and see if its related based on the entities it found. 
The content is expected to be saved with in this path: "/enrich/content/"


TODO: 
Look at using the classifier for training maybe after its been tagged
