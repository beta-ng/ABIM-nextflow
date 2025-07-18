nextflow.enable.dsl=2

// ====================================================================================
// Process 1: 从 S3 读取文件名
// - input: 一个指向 S3 文件的路径 (path)
// - output: 文件内容被放入一个 Channel
// ====================================================================================
process READ_NAME_FROM_S3 {
    container "ubuntu:22.04" // 这个容器不需要特殊工具，cat 就够了

    input:
    path user_file // Nextflow 会自动处理 S3 路径，将文件拉到工作目录

    output:
    stdout into name_channel // 将标准输出（即文件内容）发送到 'name_channel'

    script:
    """
    cat ${user_file}
    """
}

// ====================================================================================
// Process 2: 打印问候语
// - input: 从 channel 中接收一个值 (val)
// ====================================================================================
process GREET_USER {
    container "ubuntu:22.04"

    input:
    val user_name

    output:
    stdout

    script:
    """
    echo "Hello, ${user_name}! Welcome to the advanced test."
    """
}


// ====================================================================================
// Workflow: 定义工作流
// - 将参数中定义的 S3 文件路径传入第一个 process
// - 将第一个 process 的输出通过 Channel 传递给第二个 process
// ====================================================================================
workflow WORKER {
    // 从 params 中获取 S3 文件路径，并将其放入 Channel
    Channel
        .fromPath(params.source_s3_paths)
        .ifEmpty { error "S3 user file path not specified! Please set params.source_s3_paths" }
        .set { user_s3_file_ch }
    
    // 执行工作流
    READ_NAME_FROM_S3(user_s3_file_ch)
    GREET_USER(name_channel)
    
    // 打印最终的输出
    GREET_USER.out.view()
}