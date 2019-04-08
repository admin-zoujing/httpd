#!/bin/bash
1 正向代理
httpd通过ProxyRequests指令配置正向代理的功能。
ProxyRequests On
ProxyVia On

<Proxy "*">
  Require host internal.example.com
</Proxy>
其中< Proxy >容器是只有internal.example.com下的主机可以通过该正向代理去访问任意URL的请求内容。ProxyVia指令表示在响应首部中添加一个Via字段。


2 反向代理
2.1 简单的反向代理配置

ProxyPass指令用于映射请求到后端服务器。最简单的代理是对所有请求"/"都映射到一个后端服务器上：
ProxyPass "/"  "http://www.example.com/"
ProxyPassMatch "^/((?i).*\.php)$" "fcgi://127.0.0.1:9000/var/www/a.com/$1"

为了地址重定向时也能正确使用反向代理，应该使用ProxyPassReverse指令。
ProxyPass "/"  "http://www.example.com/"
ProxyPassReverse "/"  "http://www.example.com/"

或者只为特定的URI进行代理，例如下面的配置，只有/images开头的路径才会代理转发，其他的所有请求都在本地处理。
ProxyPass "/images"  "http://www.example.com/"
ProxyPassReverse "/images"  "http://www.example.com/"
假如本地服务器地址为http://www1.example.com，当请求http://www1.example.com/images/a.gif时，将代理为http://www.example.com/a.gif。

2.2 负载均衡：后端成员
添加后端节点方法使用< proxy >容器将后端节点定义成一个负载均衡组，然后代理目标指向组名即可。

<Proxy balancer://myset>
    BalancerMember http://www2.example.com:8080
    BalancerMember http://www3.example.com:8080
    ProxySet lbmethod=bytraffic
</Proxy>

ProxyPass "/images/"  "balancer://myset/"
ProxyPassReverse "/images/"  "balancer://myset/"


httpd有3种复杂均衡算法：
byrequests：默认。基于请求数量计算权重。
bytraffic： 基于I/O流量大小计算权重。
bybusyness：基于挂起的请求(排队暂未处理)数量计算权重。


添加权重比例，使得某后端节点被转发到的权重是另一节点的3倍，等待后端节点返回数据的超时时间为1秒。
<Proxy balancer://myset>
    BalancerMember http://www2.example.com:8080
    BalancerMember http://www3.example.com:8080 loadfactor=3 timeout=1
    ProxySet lbmethod=byrequests
</Proxy>

ProxyPass "/images"  "balancer://myset/"
ProxyPassReverse "/images"  "balancer://myset/"

2.3 故障转移
当所有负载节点都失败时，指定一个备份节点(standby node)。参考如下配置：

<Proxy balancer://myset>
    BalancerMember http://www2.example.com:8080
    BalancerMember http://www3.example.com:8080 loadfactor=3 timeout=1
    BalancerMember http://hstandby.example.com:8080 status=+H
    BalancerMember http://bkup1.example.com:8080 lbset=1
    BalancerMember http://bkup2.example.com:8080 lbset=1
    ProxySet lbmethod=byrequests
</Proxy>

ProxyPass "/images/"  "balancer://myset/"
ProxyPassReverse "/images/"  "balancer://myset/"
其中成员1、2、4、5是负载节点，成员3是备份节点。当所有负载节点都不健康时，将转发请求给备份节点，并由备份节点处理请求，httpd设置备份节点的方式很简单，只需将状态设置为"H"，表示hot-standby。还需注意的是负载节点4、5，它们额外的参数为lbset=1，不写时默认为0，这是负载均衡时的优先级设置，负载均衡时总是先转发给低数值的节点，也就是说或数值越小，优先级越高。所以上面的配置中，当节点1、2正常工作时，只在它们之间进行负载，此时节点4、5处于闲置状态。只有当节点1、2都失败时，才会在节点4、5之间进行负载。

 
2.4 提供负载状态显示页面
<Location "/bm">
    SetHandler balancer-manager
    Require host localhost
    Require ip 192.168.100
</Location>
然后在浏览器中输入http://server/bm即可。