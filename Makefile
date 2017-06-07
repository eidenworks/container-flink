LOCAL_IMAGE=container-flink
FLINK_IMAGE=eidenworks/-container-flink

# If you're pushing to an integrated registry
# in Openshift, FLINK_IMAGE will look something like this

# FLINK_IMAGE=172.30.242.71:5000/myproject/container-flink

.PHONY: build clean push create destroy

build:
	docker build -t $(LOCAL_IMAGE) .

clean:
	docker rmi $(LOCAL_IMAGE)

push: build
	docker tag $(LOCAL_IMAGE) $(FLINK_IMAGE)
	docker push $(FLINK_IMAGE)

create: push template.yaml
	oc process -f template.yaml -v FLINK_IMAGE=$(FLINK_IMAGE) > template.active
	oc create -f template.active

destroy: template.active
	oc delete -f template.active
	rm template.active
