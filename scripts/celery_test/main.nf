/*
 * ========================================================================================
 * Nextflow script to test S3 Read -> Process -> S3 Write for the ABIM flow service.
 * ========================================================================================
 * This script is designed to:
 * 1. Read an input file from an S3 path provided by the flow service.
 * 2. Process the content of the file inside a container.
 * 3. Publish a result file to the S3 path provided by the flow service.
 * ========================================================================================
 */

workflow WORKER_TEST {
    main:
        input_file_ch = channel.fromPath( params.source_s3_paths[0] )

        GREETING_FROM_FILE( input_file_ch )
}

process GREETING_FROM_FILE {
    tag "Reading user from ${user_file}"

    publishDir params.results_s3_path, mode: 'copy'
    
    container 'ubuntu:22.04'

    input:
        path user_file

    output:
        path "greeting.txt"

    script:
    """
    set -e
    
    apt-get update -qq && apt-get install -y -qq coreutils
    
    echo "========= S3 Read/Write Test: START ========="
    
    if [ ! -f "${user_file}" ]; then
        echo "Error: Input file ${user_file} not found"
        exit 1
    fi
    
    USER_NAME=\$(cat ${user_file})
    
    echo "Successfully read user: '\${USER_NAME}' from S3 path: ${user_file}"
    echo "Simulating some processing..."
    sleep 5
    
    echo "Hello, \${USER_NAME}! Your file was read successfully from S3." > greeting.txt
    
    echo "Process finished at: \$(date)"
    echo "========= S3 Read/Write Test: END ========="
    """
}