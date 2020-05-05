build:
	cfcompile simple-instance
	cp out/yaml/simple-instance.compiled.yaml template.yaml
	aws cloudformation validate-template --template-body file://template.yaml
