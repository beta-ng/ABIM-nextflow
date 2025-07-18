
nextflow.enable.dsl=2

process SIMPLE_ECHO {
  
  container "ubuntu:22.04"

  input:
    val message

  output:
    stdout

  script:
    """
    echo "Message from the pod: ${message}"
    """
}


workflow WORKER {
  
  Channel.of('Hello Kubernetes from Nextflow!') | SIMPLE_ECHO | view
}