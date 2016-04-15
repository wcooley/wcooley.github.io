---
tags: shell
category: "shell hacks"
title: "Batch Processing"
---
Batch Processing
=============================

If you've ever wanted to run a number of jobs at the same time, but had too
many jobs to run them all at the same time, you can batch the jobs, so you can
run **N** jobs in parallel at a time.  Here's what it would look like:

```
batchsize=5
batch=0

for x in $(seq -w 1 30); do
    # Start background task here
    (sleep 1; echo $x) &

    batch=$(($batch + 1))

    if [ $((${batch} % ${batchsize})) -eq 0 ]; then
        wait
        echo "End of batch: $x"
    fi
done

echo "Processed ${batch} items"

```


