// File: main.nf (Corrected)
nextflow.enable.dsl=2

// ====================================================================================
// Process 1: 从 S3 读取文件名
// - output: 使用 'emit' 关键字命名输出通道
// ====================================================================================
process READ_NAME_FROM_S3 {
    container "ubuntu:22.04"

    input:
    path user_file

    output:
    stdout emit: name_ch // 修改点 1: 使用 'emit' 来命名输出

    script:
    """
    cat ${user_file}
    """
}

// ====================================================================================
// Process 2: 打印问候语
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
// - 将一个流程的输出通道 (out) 作为另一个流程的输入
// ====================================================================================
workflow WORKER {
    Channel
        .fromPath(params.source_s3_paths)
        .ifEmpty { error "S3 user file path not specified! Please set params.source_s3_paths" }
        .set { user_s3_file_ch }
    
    // 执行工作流
    READ_NAME_FROM_S3(user_s3_file_ch)
    
    // 修改点 2: 显式地将第一个流程的输出(out.name_ch)连接到第二个流程
    GREET_USER(READ_NAME_FROM_S3.out.name_ch) 
    
    // 打印最终的输出
    GREET_USER.out.view()
}