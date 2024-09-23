## EBS

```bash
$ lsblk
$ sudo file -s /dev/xvdf
$ sudo mkfs -t xfs /dev/xvdf
$ sudo mkdir /foo
$ sudo mount /dev/xvdf /foo
$ df -k
```

## Improvements

- implement multi-attach so the EBS volume can be attached to many instances at a time
    + of course, implement a strategy to concurrent writes aren't over-writing each other

