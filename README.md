# Deploy a Rails app with Docker Compose

## Cài đặt Docker và Docker Compose

```bash
# cài docker bằng lệnh curl
curl -fsSL https://get.docker.com/ | sh

# Cài đặt docker-compose
COMPOSE_VERSION=`git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | tail -n 1`
sudo sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
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

## Build Dockerfile cơ bản

* Với 1 app Rails 6 cơ bản, thực hiện build 1 image với Dockerfile như sau:

```Dockerfile
FROM ruby:2.6.5

# Thực hiện cài đặt một số tool cơ bản
RUN apt-get update && apt-get install -y build-essential curl cron logrotate gettext-base nano
RUN apt-get clean
# Với Rails 6 phải cài đặt thêm yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# Tạo thư mục làm việc
RUN mkdir -p /app
WORKDIR /app

# Copy Gemfile phục vụ cho việc bundle khi build, code sẽ được mount trong config của Compose
COPY ./Gemfile /Gemfile
COPY ./Gemfile.lock /Gemfile.lock

# Định nghĩa path lưu các gem được cài đặt
ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Nếu sử dụng bundler 2.0.2
RUN gem install bundler -v 2.0.2

# Expose app ra port 3000 trong container
EXPOSE 3000
```

* File docker-compose cơ bản run 2 container là app và db

```yml
version: "3"

services:
  db:
    image: mysql:8.0.13 #Sử dụng images offical
    ports:
      - 3306:3306 #bind port 3306 trong container (bên phải) ra 3306 của host (bên trái)
    volumes:
      - db-data:/var/lib/mysql #Sử dụng volume để lưu dữ liệu tránh mất mát mỗi lần rebuild container
    env_file: .env #Khai báo các biến môi trường
    networks:
      - demo_docker
  app:
    build: # Sử dụng images build từ dockerfile
      context: .
      dockerfile: docker/app/Dockerfile
    command: docker/common/wait-for-it.sh db:3306 -- docker/app/entrypoint.sh #command sau khi build container thành công
    volumes:
      - .:/app
      - bundle:/bundle
    ports:
      - 3000:3000
    env_file: .env
    stdin_open: true
    tty: true
    networks:
      - demo_docker
volumes:
  db-data:
  bundle:
networks:
  demo_docker:
    external:
      name: demo_docker #define network để các container connect với nhau
```

* Các file liên quan:
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
