TFTP（Trivial File Transfer Protocol,简单文件传输协议）是TCP/IP协议族中的一个用来在客户端与服务器之间进行简单文件传输的协议。和使用TCP的文件传输协议（FTP）不同，为了保持简单短小，TFTP使用了UDP。TFTP的实现（和它所需要的UDP、IP、和设备驱动程序）可以放入只读存储器中<br>
TFTP是一个简单的协议，适合于只读存储器，仅用于无盘系统进行系统引导，它只使用几种报文格式，是一种停止等待协议<br>
<br>
使用oc实现了tftp server<br>
协议本身很简单，可参考https://www.cnblogs.com/qingtianyu2015/p/5851551.html<br>
服务端就是开启一个监听，然后收到客户端的request请求 然后解析出name  然后根据对应的name去获取相应的文件路径 将数据发送给client
