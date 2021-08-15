# Deploy a Rails app with Docker Compose

## Cài đặt Docker và Docker Compose

```bash
# cài docker bằng lệnh curl
curl -fsSL https://get.docker.com/ | sh

# Cài đặt docker-compose
https://docs.docker.com/compose/install/

# Thêm current user vào docker group để khỏi dùng sudo
sudo usermod -aG docker $USER
sudo reboot
```

## Tổ chức các file Docker

**Ý tưởng**:
* Lưu Dockerfile, các file scripts không thay đổi giữa các môi trường vào thư mục /docker.
  * Mỗi image cần build nên đặt ở trong từng folder riêng, bao gồm Dockerfile và các file scripts liên quan.
  * Những image sử dụng trực tiếp từ offical image thì có thể khai báo thẳng trong docker-compose.
  * Những file scripts dùng chung thì để trong folder /common
* File config docker-compose sẽ khác nhau giữa các môi trường và đặt tên theo kiểu: docker-compose.[env].yml
* Khi thực hiện các lệnh với docker-compose thì thêm cờ -f trỏ tới file config. Ví du: `docker-compose -f docker-compose.dev.yml up`. Vì đoạn `docker-compose -f docker-compose.dev.yml` là giống nhau trong 1 môi trường nên có thể đặt alias cho ngắn gọn.

## Build Dockerfile và config Docker Compose cơ bản
- [docker/ruby/Dockerfile](https://github.com/lequangcanh/docker-demo/blob/master/docker/ruby/Dockerfile)
- [docker-compose.dev.yml](https://github.com/lequangcanh/docker-demo/blob/master/docker-compose.dev.yml)

## Các file liên quan:
  * docker/app/entrypoint.sh: Tập hợp các task của app chạy mỗi lần deploy
  * docker/common/wait-for-it.sh: Script yêu cầu đợi. Cụ thể container app sẽ phải đợi db khởi tạo xong mới được chạy, tránh bị lỗi không connect được

## Thực hiện build và deploy
1. Đặt alias để giản lược câu lệnh của docker-compose
```bash
alias dc="docker-compose -f docker-compose.dev.yml"
```
2. Cấp quyền thực thi cho các file .sh:
* Có 2 cách cấp quyền thực thi cho các file .sh.
  * Một là cấp quyền ngay trong Dockerfile, ưu điểm là không bị miss, thực hiện tự động. Tuy nhiên nhược điểm là mỗi lần có thay đổi trong những file .sh này thì sẽ phải build lại images
  * Hai là thực hiện cấp quyền ngay bên ngoài host rồi mount vào container. Ưu điểm là thay đổi file này chỉ cần build lại container thay vì build lại toàn bộ images, nhược điểm là dễ miss file, phải thực hiện thủ công

```bash
chmod +x docker/*/*.sh
```


3. Create network
```bash
docker network create demo_docker
```

4. Build các images
```bash
dc build
```

5. Build container
```bash
dc up
hoặc
dc up -d # chạy ở chế độ daemon
```

6. Stop and remove container
```
dc down
```

## Một số lưu ý

* **depends_on:** Start service theo thứ tự trong list depends_on trước. Tuy nhiên, nó chỉ đợi start service chứ không đợi service "ready", vì vậy những service phụ thuộc cần phải đợi "ready" (ví dụ app phải đợi DB khởi tạo thành công mới migrate được) thì nên sử dụng scripts `docker/common/wait-fot-it.sh`
