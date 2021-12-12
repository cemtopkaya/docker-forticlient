# forticlient

Kullanılan yansı [auchandirect/forticlient](https://hub.docker.com/r/auchandirect/forticlient/) eğer bulunamazsa ubuntu yansısına aşağıdaki forticlient-sslvpn paketini kurarak istediğiniz yansıyı oluşturabilirsiniz. 

Örneğin:
```Dockerfile
FROM ubuntu:xenial
RUN echo "deb [arch=amd64] https://repo.fortinet.com/repo/6.4/ubuntu/ xenial multiverse" > /etc/apt/sources.list.d/forti.list
RUN apt-get update
RUN apt-get install -y forticlient
```

Farklı linux sürümlerine kurulum için:
- Paket yöneticileri için (yum, apt v.s) paket havuzlarını nasıl ekleyebileceğinizi [bu adresten](https://www.fortinet.com/support/product-downloads/linux) görebilirsiniz.
- [Forti client ubuntu paketleri](https://hadler.me/linux/forticlient-sslvpn-deb-packages/)

Konteyner içinde `forticlient-sslvpn_amd64.deb` paketinin kurulmuş ve `start.sh` betiğinin çalışmasıyla bağlantı kurar.
`start.sh` İçinde:
- Ortam değişkenlerinde şunların boş olmamasını ister: `$VPNADDR`, `$VPNUSER`, `$VPNPASS"`
- Linux üstünde NAT yaparak:
![image](https://user-images.githubusercontent.com/261946/145686394-c9277b6d-b6ec-458e-b8b9-8ac1587ca591.png)
```bash
$ for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE; done
$ iptables -t nat -L
```
![image](https://user-images.githubusercontent.com/261946/145708016-7acd9ee7-4356-4fc7-840c-34ed3f6d3b99.png)
[ref: nat-list](https://www.cyberciti.biz/faq/how-to-list-all-iptables-rules-in-linux/)
---

### NAT ve IPTables'a Dair
Linux 2.2 öncesinde firewall rule editorü **ipfwadm** idi, sonra yerini **ipchains**'e ve daha da sonra **iptables**'a bıraktı. iptables sanılanın aksine uygulama katmanında değil, network ve transport katmanlarında çalışan kernel seviyesindeki yazılımdır. Belirli bir süre geçerli olacak kurallar tanımlamaya izin veren libipt_time.so adında bir time modülü vardır.

Örnekler
1. Hafta içi mesai saatleri arasında `sozluk.sourtimes.org` adresine erişimi engelleyen kural:
```bash
$ iptables -i output -m time --timestart 09:00 --timestop 17:00 --days mon,tue,wed,thu,fri -d sozluk.sourtimes.org -j reject
```
2. `server.php` adresine giden trafiği engeller (düşürür). [ekşi-iptables](https://eksisozluk.com/iptables--133344)
```bash
$ iptables -i input -m string --algo bm --string 'server.php' -j drop
```

Peki NAT nedir ve iptables ile ilişkisini nasıl kurabiliriz?

> nat (network address translation) ileride(ipv6 düşünülmeden önce) oluşabilecek potansiyel ip sıkıntısı düşünülerek geliştirilmiştir. bir network içerisinde bilinen bir ip adresinin başka bir network tarafından erişilebilmesine yarar. biri içeride, biri dışarıda iki network ü bağlamak amaçlanmıştır. tipik ofis, internet cafe internet bağlantılarında kullanılır. dışarı veya içeri yönde her request tanımlanmış, önceden bekleniyor, bir öncekine cevap yada tekrar niteliğinde olması beklenir. ip sıkıntısı yada maliyet nedeni ile tercih edilir.[ekşi-nat](https://eksisozluk.com/nat--54679)

> temel olarak, bir public ip adresi ile, birden çok private ip adresinin internete erişimini sağlar.
çünkü yerel ağlarda* kullanılan private ip adresleri, internette kullanılamaz.

nat ve port-forwarding kavramını anlamak için telefon santralini örnek alalım. Şirketlerde kurulu olan, aradığınızda "lütfen dahili numarayı çeviriniz veya operatöre bağlanmak için bekleyiniz" karşılamasının sorumlusu olan sistemleri düşünelim. Karel'in [MS26 santralinin](https://www.karel.com.tr/urun-cozum/ms26-serisi-telefon-santrallari) şirketinizde kullanılıyor olduğunu düşünün.
> 2 dış hat ve 6 dahili kullanıcıya ek olarak 4 IP dış hat ve 24 IP abone kapasitesine ulaşabilen telefon santralları
1 Dış hattın (PSTN) bağlı ve telefon numarasını 0212 216 12 16 olsun. Santralinize bağlı 6 dahili hattınız takılı olduğunda gelen arama dahili hatlardan birini tuşlayarak içerideki dahiliye ulaşsın. [ekşi-nat](https://eksisozluk.com/nat--54679?p=4)

---

Devam edelim...
Sadece kullanıcı adı ve şifresiyle doğrulama yapıyorsanız ortam değişkenleriyle bilgileri verebilir. Konteyner başlar başlamaz otomatik olarak bağlantı kurulacaktır.

Eğer iki etkili doğrulama (kullanıcı adı ve şifresinden sonra bir de ileti veya SMS ile gelen kodu) kullanıyorsanız bu kez bağlantı kuramayacağınız için konteynere konsolunuzu bağlayarak aşağıdaki komutu elle çalıştırarak bağlantı kurabilirsiniz.
```bash
$ cd /usr/share/forticlient/opt/forticlient-sslvpn/64bit/
$ ./forticlientsslvpn_cli --server 176.236.170.162:443 --vpnuser cem.topkaya
.... şifrenizi soracaktır,
.... sonrasında gelecek kodunuzu gireceğiniz satırda bekleyecek,
.... kodu girdikten sonra bağlantınız kurulacaktır.
```

Önce `bridge` türünde bir ağ oluşturacağız (sanal ağ türleri için [ip-link kılavuzuna bkz](https://man7.org/linux/man-pages/man8/ip-link.8.html)). 

![image](https://user-images.githubusercontent.com/261946/145689849-b386bf6e-0684-4041-a0ad-a3768cfe8cd5.png)

Bu ağda; hem VPN bağlantısını kuracağınız konteyner hem de bu konteyner üstünden VPN ağına erişmek istediğiniz konteynerler olacaktır.
```bash
# bir ağ yaratalım ki buradaki konteynerler VPN bağlantılı konteyneri GATEWAY olarak alıp VPN ağına çıkabilsinler
$ docker network create    \
  --driver=bridge          \
  --subnet=172.30.1.0/16   \ # 255.255.0.0 olacak şekilde alt ağ maskesi ayarlıyoruz 
  --ip-range=172.30.1.0/24 \ # 172.30.1.1-254 arasında IP dağıtacağız
  --gateway=172.30.1.254   \ # Kapımız ...254 IP adresinden olacak
  fortinet                   # Ağın adı fortinet olsun
```` 

> Alt ağı 16 olarak ayarladığımızda [192.168.0.0/16](http://jodies.de/ipcalc?host=192.168.0.0&mask1=16&mask2=) nasıl bir ağa erişebildiğimizi görebiliriz.
> ![image](https://user-images.githubusercontent.com/261946/145690248-2210e97a-814a-4cad-871e-5446b924731f.png)


Şimdi oluşturduğumuz `fortinet` ağına bir bakalım:
```bash
C:\>docker inspect fortinet
[
    {
        "Name": "fortinet",
        "Id": "2b48262c094a045012372af63d3008ba8c409d839af9754c587e0accad30f857",
        "Created": "2021-12-11T20:20:41.7355242Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.30.1.0/24",
                    "IPRange": "172.30.1.0/24",
                    "Gateway": "172.30.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]

C:\>
```

Şimdi VPN bağlantısı kurmak istediğimiz docker konteynerini başlatalım:
```bash
$ docker run                         \
     -it                             \ # şifre veya bir cevap vermemiz için interactive terminal yapıyoruz
     --rm                            \ # konteynerden çıkıldığında otomatik silinsin
     --privileged                    \ # root yetkisinde konteyner başlatılsın
     --net fortinet                  \ # az önce oluşturduğumuz network'e bağlansın ki, diğer konteynerleri buraya bağlayıp üstünden çıksınlar
     --ip 172.30.1.2                 \ # konteynerin IP'sini sabitleyelim ki routingi bu IP üstünden yapalım
     -e VPNADDR=176.236.170.162:443  \ # VPN sunucusunun IP adresi ve port bilgisi
     -e VPNUSER=cem.topkaya          \ # VPN kullanıcı adı
     -e VPNPASS=kullaniciSifresi     \
     --mac-address=E8-6A-64-BE-F8-47 \ # konteyner MAC adresini bilgisayarın MAC'i ile aynı yapalım ki doğrulansın
     auchandirect/forticlient
```

Windows konsolda tek satırda çalıştırmak için:
```bash
$ docker run --name=vpn -it --rm --privileged --net=fortinet --ip=172.30.0.2 -e VPNADDR=176.236.170.162:443 -e VPNUSER=cem.topkaya -e VPNPASS=sifre --mac-address=22-11-FF-CC-BB-AA  auchandirect/forticlient
```

```bash
$ docker exec -it --user root vpn bash 
$ echo 1 > /proc/sys/net/ipv4/ip_forward
$ iptables -A FORWARD -i eth0 -o ppp0 -j ACCEPT
$ iptables -A FORWARD -i ppp0 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
$ iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
```

Kontrol etmek için:
```bash
$ iptables -L
$ iptables -S
```

Oluşan IP tablosunu ihraç ve ithal etmek için:
```bash
$ iptables-save > ~/ruleset-v4
$ iptables-restore < ~/ruleset-v4
```

Şimdi Grafana'yı konteyner içinde çalıştırıp VPN ağındaki bir sunucuya erişmek isteyelim.
Önce Grafana konteynerinin docker-compose dosyası:
```bash
# docker-compose -f "docker-compose.yaml" up -d --build grafana 
# docker-compose -f "docker-compose.yaml" down
version: '3'

# Bu dosyanın dışında oluşturulduğu için 'external: true' olarak işaretleniyor.
networks:
  fortinet:
    external: true
    name: fortinet

services:
  grafana:
    # fortinet ağına dahil olacak ki VPN ağına erişebilsin
    networks:
      - fortinet
    container_name: cgrafana
    image: grafana/grafana
    privileged: true 
    environment:
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - "./grafana/datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml"
    ports:
    - 3000:3000
```

datasources.yml
```yaml
apiVersion: 1
datasources:
  - name: prometheus-ulak
    type: prometheus
    access: proxy
    orgId: 1
    url: http://172.19.0.85:31355
    isDefault:
    version: 1
    editable: true
```

Grafana'yı ayaklandırıp VPN ağındaki `172.19.0.85` makinaya erişebilmesi için ip routing ayarını yapacağız:
```bash
$ docker-compose  -f "docker-compose.yaml" up -d --build grafana 
docker exec -it --user root cgrafana route add -net 172.19.0.85/32 gw 172.30.1.2
```

## Usage

The container uses the forticlientsslvpn_cli linux binary to manage ppp interface

All of the container traffic is routed through the VPN, so you can in turn route host traffic through the container to access remote subnets.

### Linux

```bash
# Create a docker network, to be able to control addresses
$ docker network create --subnet=172.20.0.0/16 fortinet

# Start the priviledged docker container with a static ip
$ docker run -it --rm \
  --privileged \
  --net fortinet --ip 172.20.0.2 \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  auchandirect/forticlient

# Add route for you remote subnet (ex. 10.201.0.0/16)
$ ip route add 10.201.0.0/16 via 172.20.0.2

# Access remote host from the subnet
$ ssh 10.201.8.1
```

### OSX

```
UPDATE: 2017/06/10
Docker's microkernel still lacks ppp interface support, so you'll need to use a docker-machine VM.
```

```bash
# Create a docker-machine and configure shell to use it
docker-machine create fortinet --driver virtualbox
eval $(docker-machine env fortinet)

# Start the priviledged docker container on its host network
docker run -it --rm \
  --privileged --net host \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  auchandirect/forticlient

# Add route for you remote subnet (ex. 10.201.0.0/16)
sudo route add -net 10.201.0.0/16 $(docker-machine ip fortinet)

# Access remote host from the subnet
ssh 10.201.8.1
```

## Misc

If you don't want to use a docker network, you can find out the container ip once it is started with:
```bash
# Find out the container IP
docker inspect --format '{{ .NetworkSettings.IPAddress }}' <container>

```

### Precompiled binaries

Thanks to [https://hadler.me](https://hadler.me/linux/forticlient-sslvpn-deb-packages/) for hosting up to date precompiled binaries which are used in this Dockerfile.
