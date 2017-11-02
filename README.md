
使用oc简单的实现了tftp server
协议本身很简单，可参考http://linux.chinaunix.net/techdoc/net/2009/05/04/1109928.shtml
服务端就是开启一个监听，然后收到客户端的request请求 然后解析出name  然后根据对应的name去获取相应的文件路径 将数据发送给client

第一个版本是简单实现，下个版本添加client断线控制。
