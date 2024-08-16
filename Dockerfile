# Copyright © 2021 Yonatan Kahana
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM harbor.artsland.space/proxy/library/alpine:3.13 AS tzdata

ARG tzdbversion=2024a
RUN \
    apk add build-base lzip && \
    wget -O tzdb.tar.lz https://data.iana.org/time-zones/releases/tzdb-$tzdbversion.tar.lz && \
    lzip -cd tzdb.tar.lz | tar -xf - && \
    mv tzdb-* tzdb && \
    cd tzdb && \
    mkdir build && \
    make TOPDIR=build install
FROM harbor.artsland.space/proxy/library/golang:1.22.6 AS build
ENV CGO_ENABLED=0
WORKDIR /build
COPY ./k8tz .
RUN go env -w GO111MODULE=on
RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN make build

FROM harbor.artsland.space/proxy/library/alpine:3.13
RUN apk add --no-cache tzdata
COPY --from=tzdata /tzdb/build/usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /build/build/k8tz /opt/k8tz/bin/k8tz
USER 1000
ENTRYPOINT ["/opt/k8tz/bin/k8tz"]
