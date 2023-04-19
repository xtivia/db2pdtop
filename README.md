# db2pdtop.pl

Utility for Monitoring Db2 EDUs

When monitoring CPU utilization on a Db2 server, each Db2 instance 
generally has a single `db2sysc` process consuming CPU on the server. The 
db2sysc process is made up of many threads.  While it's possible to see 
CPU utilization of each thread within the db2sysc process using `top -H`,
this view does not provide useful information because each thread is 
shown only as "db2sysc".

`db2pdtop.pl` displays which threads (Engine Dispatchable Units or EDUs) 
within the db2sysc process are consuming CPU.  `db2pdtop.pl` uses similar 
command-line options as top, and displays CPU information about both the 
Db2 processes for the instance as well as the EDUs within the db2sysc 
process.

`db2pdtop.pl` relies on `db2pd`, and therefore must be executed by a user 
with SYSADM privileges.

## Usage

Usage:
    db2pdtop.pl [OPTION]...

Options:

    -d, --delay *delay_time*
            Update every *delay_time* seconds. Defaults to 5 seconds.

    -t, --top *nprocs*
            Display top *nprocs* EDUs. Defaults to 15.

    -n, --number *number_of_iterations*
            Specifies the maximum number of iterations, or frames, top
            should produce before ending.

    -b, --batch
            Run in batch mode. Useful for feeding into other scripts.

    --help, --usage
            Print a usage statement for this utility and exit.

    --man   Print the manual page and exit.


## Example Output

```
$ ./db2pdtop.pl -b -n 1 
top - 18:54:36 up 111 days, 14:58,  1 user,  load average: 0.50, 1.37, 1.80
Tasks: 781 total,   1 running, 780 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.3 us,  0.4 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 52806768+total, 20626316+free, 14517660 used, 30728684+buff/cache
KiB Swap: 16777212 total, 16777212 free,        0 used. 23627524+avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
14461 db2inst1   20   0  143.5g 111.0g 109.2g S  17.6 22.0 104168:18 db2sysc
14647 db2inst1   20   0  679764  52408  34876 S   0.0  0.0   0:00.05 db2vend
20689 db2inst1   20   0 3161048 580748  25580 S   0.0  0.1  48:14.27 db2fmp

Database Member 0 -- Active -- Up 99 days 16:54:35 -- Date 2023-04-18-18.54.36.896392

List of all EDUs for database member 0

db2sysc PID: 14461
db2wdog PID: 14410
db2acd  PID: 20689

EDU ID   EDU Name                       % db2sysc
-------- ------------------------------ ---------
4908     db2agent (SAMPLE) 0                26.5
158      db2hadrp.0.2 (SAMPLE) 0             8.8
4907     db2agent (SAMPLE) 0                 8.8
159      db2hadrp.0.3 (SAMPLE) 0             8.8
5186     db2agent (SAMPLE) 0                 6.9
5378     db2agent (SAMPLE) 0                 5.9
4618     db2agent (SAMPLE) 0                 4.9
5017     db2agent (SAMPLE) 0                 3.9
4967     db2agent (SAMPLE) 0                 3.9
5185     db2agent (SAMPLE) 0                 2.9
5000     db2agent (SAMPLE) 0                 2.9
5360     db2agent (SAMPLE) 0                 2.0
110      db2pfchr (SAMPLE) 0                 1.0
5002     db2agent (SAMPLE) 0                 1.0
5350     db2agent (SAMPLE) 0                 1.0
```