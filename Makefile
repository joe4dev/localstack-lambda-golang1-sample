# go1.x does not support arm64 architecture: https://docs.aws.amazon.com/lambda/latest/dg/lambda-golang.html
DOCKER_PLATFORM ?= linux/amd64
# Golang EOL overview: https://endoflife.date/go
DOCKER_GOLANG_IMAGE ?= golang:1.19.6

build:
	mkdir -p build && \
	docker run --rm --platform $(DOCKER_PLATFORM) -v $$(pwd)/src:/app -v $$(pwd)/build:/out $(DOCKER_GOLANG_IMAGE) /bin/bash -c "cd /app && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags=-buildid= -o /out/main main.go && chown $$(id -u):$$(id -g) /out/main" && \
	cd build && zip lambda.zip main && mv lambda.zip ..

create:
	# --handler lambda.main => main
	aws --endpoint-url=http://localhost:4566 lambda create-function \
		--function-name test-go \
		--runtime go1.x \
		--zip-file fileb://lambda.zip \
		--handler main \
		--role arn:aws:iam::000000000000:role/test-go

invoke:
	aws --endpoint-url=http://localhost:4566 lambda invoke \
		--function-name test-go \
		--cli-binary-format raw-in-base64-out \
		--payload '{"body": "{\"num1\": \"10\", \"num2\": \"10\"}" }' output.txt

clean:
	$(RM) -r build lambda.zip output.txt

.PHONY: build clean create invoke
