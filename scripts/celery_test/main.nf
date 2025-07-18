// File: main.nf (with S3 output)
nextflow.enable.dsl=2

// ====================================================================================
// Process 1: 从 S3 读取文件名 (无变化)
// ====================================================================================
process READ_NAME_FROM_S3 {
    container "ubuntu:22.04"

    input:
    path user_file

    output:
    stdout emit: name_ch

    script:
    """
    cat ${user_file}
    """
}

// ====================================================================================
// Process 2: 打印问候语 (无变化)
// ====================================================================================
process GREET_USER {
    container "ubuntu:22.04"

    input:
    val user_name

    output:
    stdout emit: greeting_ch // 为了清晰，给输出通道起一个更有意义的名字

    script:
    """
    echo "Hello, ${user_name}! Welcome to the advanced test."
    """
}

// ====================================================================================
// 新增 Process 3: 将问候语写入文件并发布到 S3
// - input: 从 GREET_USER 接收问候语文本
// - output: 生成一个名为 greeting.txt 的文件
// - publishDir: Nextflow 的核心功能，将指定的输出文件/目录发布到目标位置
// ====================================================================================
process WRITE_GREETING_TO_S3 {
    // publishDir 指令会自动将 'greeting.txt' 文件上传到 params.results_s3_path
    // mode: 'copy' 表示直接复制，如果目标文件已存在则会覆盖
    publishDir "${params.results_s3_path}", mode: 'copy', overwrite: true

    container "ubuntu:22.04"

    input:
    val greeting_text // 从 GREET_USER.out.greeting_ch 接收问候语

    output:
    path "greeting.txt" // 声明此流程会产生一个名为 greeting.txt 的文件

    script:
    """
    echo "${greeting_text}" > greeting.txt
    """
}


// ====================================================================================
// Workflow: 更新工作流定义
// - 连接新的流程
// ====================================================================================
workflow WORKER {
    Channel
        .fromPath(params.source_s3_paths)
        .ifEmpty { error "S3 user file path not specified! Please set params.source_s3_paths" }
        .set { user_s3_file_ch }
    
    // 流程链: READ -> GREET -> WRITE
    READ_NAME_FROM_S3(user_s3_file_ch)
    
    GREET_USER(READ_NAME_FROM_S3.out.name_ch)
    
    // 将 GREET_USER 的输出连接到新的 WRITE_GREETING_TO_S3 流程
    WRITE_GREETING_TO_S3(GREET_USER.out.greeting_ch)
}