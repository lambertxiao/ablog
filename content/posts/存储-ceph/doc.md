

Ceph

- Monitor 持有整个集群的状态，包含monitor映射，manager映射，osd映射，mds映射，crush映射，monitor必须做冗余和高可用

- Manager 负责追踪运行时指标以及集群的状态，对外提供了web端的dashboard和restapi

- OSD 负责存储数据，处理数据多副本，数据修复，rebalance，并且提供一些监控信息给monitor，同样需要冗余和高可用

- MDS 负责存储集群的数据，只有ceph文件存储才需要用到，ceph的块存储和对象存储用不到，MDS允许通过posix文件接口来访问

ceph使用一个叫逻辑存储池的方法来存储数据，数据以对象的形式存在。ceph会计算对象属于哪个group，group又属于哪个OSD，通过一个叫CRUSH的算法来实现。CRUSH算法使得ceph集群可伸缩，rebalance，可修复

