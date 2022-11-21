# CNCF TOC Vote Monitoring

This is a little python program that fetches responses to a call for votes from the [CNCF TOC mailing list](https://lists.cncf.io/g/cncf-toc/topics) and outputs the results to an HTML page.

It is pretty hard-coded to the original use case of monitoring the [Flux graduation call for votes](https://lists.cncf.io/g/cncf-toc/topic/vote_flux_for_graduation/95047098) but could be adapted easily to watch other topics. Also the list of TOC members is hard-coded.

## Running

Set the two environment variables `LISTS_CNCF_IO_USER` and `LISTS_CNCF_IO_PASSWORD` and run the script. It will then output the vote results in the `index.html` file. Optionally you may set the `OUTPUT` environment variable to a directory that the `index.html` file shall be placed in.
