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
        input_file_ch = channel.fromS3( params.source_s3_paths[0] )

        GREETING_FROM_FILE( input_file_ch )
}

process GREETING_FROM_FILE {
    tag "Reading user from ${user_file}"

    publishDir params.results_s3_path, mode: 'copy'

    input:
        path user_file

    output:
        path "greeting.txt"

    script:
    """
    echo "========= S3 Read/Write Test: START ========="

    USER_NAME=\$(cat ${user_file})

    echo "Successfully read user: '\${USER_NAME}' from S3 path: ${user_file}"
    echo "Simulating some processing..."
    sleep 5

    echo "Hello, \${USER_NAME}! Your file was read successfully from S3." > greeting.txt

    echo "Process finished at: \$(date)"
    echo "========= S3 Read/Write Test: END ========="
    """
}