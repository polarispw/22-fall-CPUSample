# Sample CPU

## 简单说明

1. 该CPU现在可以执行`ori lui addiu beq`这四种指令，但并没有完成数据相关，请自行添加相关数据通路。

2. 之后出现的问题可直接在群里提问，然后会被记录在这里形成Q&A。

3. 请使用`Github`进行版本管理，便于验收时检查。如果因为误操作导致一些记录被抹掉或者需要更换仓库请及时通知助教。

***

## 使用方法

1. 在服务器上准备好文件夹，导入`SampleCPU`内的所有`.v .vh`文件
2. 启动路径`nscscc_group/func_test_v0.01/soc_sram_func/run_vivado/mycpu_prj1`下的`mycpu.xpr`项目
3. 在`Vivado`中添加源文件，把`SampleCPU`内的所有`.v .vh`文件都导入（包括lib文件夹下）
4. 点击`Simulation`进行仿真，第一次仿真时会对项目使用的`ip`核进行综合，可能需要等待10分钟左右
5. 点击&#x25B6;进行仿真，如果波形图卡住可在下方的控制台看到提示信息，这是龙芯实验平台提供的比对机制，会告诉你当前在哪条指令出现错误，根据汇编指令和你学的流水线知识进行debug
6. 运行的汇编指令可在`nscscc_group/func_test_v0.01/soft/func/obj/test.s` 该文件中查找。`VSCode`打开搜索pc值即可，`9fc`开头的pc值在汇编文件中以`bfc`查找就可以。
7. 指令集文件可在`doc`文件夹的`A03`中查看。
8. 其他相关问题基本都可在`doc`文件夹或参考书籍中找到答案。
10. 欢迎留言，看到会回复，另外请注意Q&A的更新。

***

## 指令添加方法

1. 阅读指令集文件，查看该指令会进行哪些操作
2. 对于IF段，`P64`之前注意跳转指令即可
3. 对于ID段
    - 需要在该级进行指令译码
    - 从寄存器中读取需要的数据
    - 完成数据相关处理
    - 生成发给EX段的控制信号
4. 对于EX段
    - `alu`模块已经提供，基本通过给`alu`提供控制信号就可以完成逻辑和算术运算
    - 对于需要访存的指令在此段发出访存请求
5. 对于MEM段
    - 接收并处理访存的结果，并选择写回结果
    - 对于需要访存的指令在此段接收访存结果
6. 对于WB段
    - 和IF段类似，暂时没有需要改动的东西

***

## &#x1F4A1; Debug建议

#### &#x1F615;不要啥问题都来问助教，尤其是让助教帮你debug，在问之前先看看文档，问问同学，大部分bug都能解决

1. 查看console（控制台）中的trace比对机制的提示，记下提示的PC值，并猜测可能发生的错误

2. 打开`test.s`文件，使用提示的PC值进行查找，查看对应的指令是什么，判断是否~~添加该指令~~完整地实现了该指令

3. 如果没~~添加指令~~完整实现，则前往 `A03`文件阅读指令集，学习对应指令的执行要求

4. 如果指令已经被添加，则到波形图中去检查运算结果错误原因

5. 当找到错误波形图时，请逐步添加其源头信号，直至发现引入错误的源信号，并改正

6. 修改后可能会出现新的错误，此时请重复步骤5

7. 可能会遇到波形图卡住或`mycpu_tb.v`一直仿真停不下来的情况，已知有两种情况：

   ```verilog
   // 代码因为逻辑环路导致某个寄存器的值在一个时钟周期内反复横跳无法仿真
   // 下面是个例子，当然你们写出的环路可能会复杂得多，debug时抓住reg去找问题
   reg[31:0] pc_r;
   wire flag;
   always @(posedge clk)
   begin
       if(flag)
       begin
           pc_r <= 32'hbfbf_fffc;
       end
       else begin
           pc_r <= 32'b0;
       end
   end
   assign flag = |pc_r ? 1'b0 : 1'b1; 
   
   // 以下是testbench中的比对逻辑，一些奇奇怪怪的写回情况会导致仿真程序一直运行下去，大家debug时要考虑清楚
   //compare result in rsing edge 
   reg debug_wb_err;
   always @(posedge soc_clk)
   begin
       #2;
       if(!resetn)
       begin
           debug_wb_err <= 1'b0;
       end
       else if(|debug_wb_rf_wen && debug_wb_rf_wnum!=5'd0 && !debug_end && `CONFREG_OPEN_TRACE)// 只有运行结果写回寄存器堆且不是0号寄存器的指令才会进行比对
       begin
           if (  (debug_wb_pc!==ref_wb_pc) || (debug_wb_rf_wnum!==ref_wb_rf_wnum)
               ||(debug_wb_rf_wdata_v!==ref_wb_rf_wdata_v) )// 如果三项中有是全X(即未赋值)，那么它将可以代表任意值并通过测试
           begin
               $display("--------------------------------------------------------------");
               $display("[%t] Error!!!",$time);
               $display("    reference: PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                         ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata_v);
               $display("    mycpu    : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                         debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata_v);
               $display("--------------------------------------------------------------");
               debug_wb_err <= 1'b1;
               #40;
               $finish;
           end
       end
   end
   ```

8. 如果添加新的指令需要改动流水线结构可以参考《自己动手做CPU》或者问助教。PS：这本书原理说的还算明白，代码真别抄了，`always`写出来的组合逻辑你们把握不住

9. 如果助教也不知道你们错在哪了，请陪他一块反思

***

## 报告要求

### 格式要求：

> 1. 正文小四号字体
> 2. 1.25倍行距
> 3. 10页左右

### 内容要求：

> 1. 封面（1页）目录（1页）PS：封面在doc文件夹里，自行取用
> 2. 每个人的工作量，总体设计，不同流水段之间的连线图，完成了多少条指令，程序运行环境及使用工具。（1-2页）
> 3. 单个流水段说明: 该流水段的整体功能说明，端口介绍，信号介绍，包含的功能模块说明，大致的结构示意图。（不要贴大段源码，可以选择一小部分，并对其进行解释。比如说贴一个选择器，介绍一下是怎么控制优先级，又或者这个选择器没有优先级，是并行选择器）（5页-8页）
> 4. 组员的实验感受，改进意见（这部分三人加起来不要超过1页）
> 5. 参考资料（1页）

### 时间安排：

> 1. 纸质版1份：~~于最后一次实验课时上交~~考虑到东B的神奇安排，时间会适当延后
> 2. 电子版：使用pdf格式，添加到小组的仓库

***

## &#x1F4AD; Q&A

- Q： 关于如何检查工作量？

  A： 建议各位同学每天写完代码都push到`Github`上，到最后代码量一目了然，工作进度也很清楚。  
  （如果一定要最后几天扎堆提交，我也愿意听你解释，当然分数好不好看就不知道了）

- Q： 拿到这个模板我应该如何入手？    

  A： 群里有《自己动手写CPU》这本书的PDF，如果对流水线、旁路、数据相关之类的内容还没有概念，可以先看看这本书。在掌握每章的内容后把该章节的内容写到自己的CPU里去。(请不要妄图直接使用这本书里的源码，最后验收的时候会检查代码，代码长什么样我还是一清二楚的。对于别的学校的代码，如果你去观摩学习，然后把里面的好东西拿来用，那我非常支持。如果你直接把别人的代码copy过来用，那看一下代码风格，问几个问题基本就露馅了，没意思的)
  
- Q： 服务器上压缩文件？
  
  A： 可以使用`tar`命令，或用`apt`命令安装`zip / unzip`。压缩包下载到本地解压即可。

- Q： 关于`9fc`地址的说明

  A： `9fc`是经过`mmu.v`模块映射的虚地址段，在`test.s`中按照`bfc`开头查找即可。但是在仿真时要严格遵守比对机制，二者并不等价。
  
- Q：有的指令在`A03`里找不到？
  
  A： 指令均未超出范围，`test.s`中针对一些指令的特殊情况使用了别名，同学们按照`pc`后记录的指令内容翻译成二进制去比对即可。
  
- Q： 要加多少指令才能通过测试点？
  
  A： 测试点和指令没有严格的对应关系，同学们可以在`test.s`中查找`n1_、n32_`等来分析测试点内容。但是有一些结构上的要求需要同学们仔细思考，不一定在哪个测试点就可能遇到，例如`forwarding解决数据相关、多周期指令插入stall`。
  
  ```verilog
  // 为了降低难度，给大家一份控制台的输出作参考（由于各组实现方式不同，通过检查点的运行时间可能会有些许差别）
  ==============================================================
  Test begin!
  ----[  14025 ns] Number 8'd01 Functional Test Point PASS!!!
          [  22000 ns] Test is running, debug_wb_pc = 0xbfc5e4d4
          [  32000 ns] Test is running, debug_wb_pc = 0xbfc5f474
  ----[  40475 ns] Number 8'd02 Functional Test Point PASS!!!
          [  42000 ns] Test is running, debug_wb_pc = 0xbfc89440
  ----[  49355 ns] Number 8'd03 Functional Test Point PASS!!!
          [  52000 ns] Test is running, debug_wb_pc = 0xbfc3ad58
          [  62000 ns] Test is running, debug_wb_pc = 0xbfc3c260
  ----[  71115 ns] Number 8'd04 Functional Test Point PASS!!!
          [  72000 ns] Test is running, debug_wb_pc = 0xbfc23898
          [  82000 ns] Test is running, debug_wb_pc = 0xbfc24c40
          [  92000 ns] Test is running, debug_wb_pc = 0xbfc2621c
          [ 102000 ns] Test is running, debug_wb_pc = 0xbfc2776c
  ----[ 104845 ns] Number 8'd05 Functional Test Point PASS!!!
          [ 112000 ns] Test is running, debug_wb_pc = 0xbfc49f0c
  ----[ 120445 ns] Number 8'd06 Functional Test Point PASS!!!
          [ 122000 ns] Test is running, debug_wb_pc = 0xbfc6a28c
          [ 132000 ns] Test is running, debug_wb_pc = 0xbfc6b22c
          [ 142000 ns] Test is running, debug_wb_pc = 0xbfc6c1cc
  ----[ 146825 ns] Number 8'd07 Functional Test Point PASS!!!
          [ 152000 ns] Test is running, debug_wb_pc = 0xbfc505e4
          [ 162000 ns] Test is running, debug_wb_pc = 0xbfc51584
  ----[ 170235 ns] Number 8'd08 Functional Test Point PASS!!!
          [ 172000 ns] Test is running, debug_wb_pc = 0xbfc037b0
          [ 182000 ns] Test is running, debug_wb_pc = 0xbfc04750
  ----[ 188135 ns] Number 8'd09 Functional Test Point PASS!!!
          [ 192000 ns] Test is running, debug_wb_pc = 0xbfc3dc08
          [ 202000 ns] Test is running, debug_wb_pc = 0xbfc3eba8
  ----[ 206035 ns] Number 8'd10 Functional Test Point PASS!!!
          [ 212000 ns] Test is running, debug_wb_pc = 0xbfc6f400
          [ 222000 ns] Test is running, debug_wb_pc = 0xbfc703a0
  ----[ 225295 ns] Number 8'd11 Functional Test Point PASS!!!
          [ 232000 ns] Test is running, debug_wb_pc = 0xbfc020b8
          [ 242000 ns] Test is running, debug_wb_pc = 0xbfc02dd0
  ----[ 242685 ns] Number 8'd12 Functional Test Point PASS!!!
          [ 252000 ns] Test is running, debug_wb_pc = 0xbfc40464
          [ 262000 ns] Test is running, debug_wb_pc = 0xbfc418b4
  ----[ 267235 ns] Number 8'd13 Functional Test Point PASS!!!
          [ 272000 ns] Test is running, debug_wb_pc = 0xbfc640a0
          [ 282000 ns] Test is running, debug_wb_pc = 0xbfc653a0
          [ 292000 ns] Test is running, debug_wb_pc = 0xbfc6667c
  ----[ 301745 ns] Number 8'd14 Functional Test Point PASS!!!
          [ 302000 ns] Test is running, debug_wb_pc = 0xbfc00d94
          [ 312000 ns] Test is running, debug_wb_pc = 0xbfc84d94
          [ 322000 ns] Test is running, debug_wb_pc = 0xbfc8612c
          [ 332000 ns] Test is running, debug_wb_pc = 0xbfc874bc
  ----[ 336175 ns] Number 8'd15 Functional Test Point PASS!!!
  ----[ 339155 ns] Number 8'd16 Functional Test Point PASS!!!
          [ 342000 ns] Test is running, debug_wb_pc = 0xbfc818ec
  ----[ 342135 ns] Number 8'd17 Functional Test Point PASS!!!
  ----[ 343805 ns] Number 8'd18 Functional Test Point PASS!!!
  ----[ 345995 ns] Number 8'd19 Functional Test Point PASS!!!
  ----[ 348185 ns] Number 8'd20 Functional Test Point PASS!!!
          [ 352000 ns] Test is running, debug_wb_pc = 0xbfc7f804
          [ 362000 ns] Test is running, debug_wb_pc = 0xbfc807a4
  ----[ 369995 ns] Number 8'd21 Functional Test Point PASS!!!
          [ 372000 ns] Test is running, debug_wb_pc = 0xbfc0a960
          [ 382000 ns] Test is running, debug_wb_pc = 0xbfc0b900
  ----[ 390395 ns] Number 8'd22 Functional Test Point PASS!!!
          [ 392000 ns] Test is running, debug_wb_pc = 0xbfc32a40
          [ 402000 ns] Test is running, debug_wb_pc = 0xbfc339e0
  ----[ 411755 ns] Number 8'd23 Functional Test Point PASS!!!
          [ 412000 ns] Test is running, debug_wb_pc = 0xbfc00d90
          [ 422000 ns] Test is running, debug_wb_pc = 0xbfc61ed0
          [ 432000 ns] Test is running, debug_wb_pc = 0xbfc62e70
  ----[ 438165 ns] Number 8'd24 Functional Test Point PASS!!!
          [ 442000 ns] Test is running, debug_wb_pc = 0xbfc7acfc
          [ 452000 ns] Test is running, debug_wb_pc = 0xbfc7bc9c
  ----[ 461575 ns] Number 8'd25 Functional Test Point PASS!!!
          [ 462000 ns] Test is running, debug_wb_pc = 0xbfc4cc08
          [ 472000 ns] Test is running, debug_wb_pc = 0xbfc4dba8
          [ 482000 ns] Test is running, debug_wb_pc = 0xbfc4eb48
  ----[ 486915 ns] Number 8'd26 Functional Test Point PASS!!!
          [ 492000 ns] Test is running, debug_wb_pc = 0xbfc6d700
          [ 502000 ns] Test is running, debug_wb_pc = 0xbfc6e6a0
  ----[ 504815 ns] Number 8'd27 Functional Test Point PASS!!!
          [ 512000 ns] Test is running, debug_wb_pc = 0xbfc8aa98
          [ 522000 ns] Test is running, debug_wb_pc = 0xbfc8ba38
  ----[ 531205 ns] Number 8'd28 Functional Test Point PASS!!!
          [ 532000 ns] Test is running, debug_wb_pc = 0xbfc780ac
          [ 542000 ns] Test is running, debug_wb_pc = 0xbfc7904c
  ----[ 551605 ns] Number 8'd29 Functional Test Point PASS!!!
          [ 552000 ns] Test is running, debug_wb_pc = 0xbfc46d3c
          [ 562000 ns] Test is running, debug_wb_pc = 0xbfc47cdc
          [ 572000 ns] Test is running, debug_wb_pc = 0xbfc48c7c
  ----[ 578015 ns] Number 8'd30 Functional Test Point PASS!!!
          [ 582000 ns] Test is running, debug_wb_pc = 0xbfc089f8
          [ 592000 ns] Test is running, debug_wb_pc = 0xbfc09998
  ----[ 598415 ns] Number 8'd31 Functional Test Point PASS!!!
          [ 602000 ns] Test is running, debug_wb_pc = 0xbfc762d8
          [ 612000 ns] Test is running, debug_wb_pc = 0xbfc77278
  ----[ 620545 ns] Number 8'd32 Functional Test Point PASS!!!
          [ 622000 ns] Test is running, debug_wb_pc = 0xbfc42534
          [ 632000 ns] Test is running, debug_wb_pc = 0xbfc434d4
  ----[ 639745 ns] Number 8'd33 Functional Test Point PASS!!!
          [ 642000 ns] Test is running, debug_wb_pc = 0xbfc0cc44
          [ 652000 ns] Test is running, debug_wb_pc = 0xbfc0dbe4
          [ 662000 ns] Test is running, debug_wb_pc = 0xbfc0eb84
  ----[ 662115 ns] Number 8'd34 Functional Test Point PASS!!!
          [ 672000 ns] Test is running, debug_wb_pc = 0xbfc07260
  ----[ 681445 ns] Number 8'd35 Functional Test Point PASS!!!
          [ 682000 ns] Test is running, debug_wb_pc = 0xbfc5b3ac
          [ 692000 ns] Test is running, debug_wb_pc = 0xbfc5c34c
          [ 702000 ns] Test is running, debug_wb_pc = 0xbfc5d2ec
  ----[ 703825 ns] Number 8'd36 Functional Test Point PASS!!!
          [ 712000 ns] Test is running, debug_wb_pc = 0xbfc57060
          [ 722000 ns] Test is running, debug_wb_pc = 0xbfc58634
          [ 732000 ns] Test is running, debug_wb_pc = 0xbfc59c88
          [ 742000 ns] Test is running, debug_wb_pc = 0xbfc5b328
  ----[ 742025 ns] Number 8'd37 Functional Test Point PASS!!!
          [ 752000 ns] Test is running, debug_wb_pc = 0xbfc1f598
          [ 762000 ns] Test is running, debug_wb_pc = 0xbfc20bc4
          [ 772000 ns] Test is running, debug_wb_pc = 0xbfc22254
  ----[ 779985 ns] Number 8'd38 Functional Test Point PASS!!!
          [ 782000 ns] Test is running, debug_wb_pc = 0xbfc70cbc
          [ 792000 ns] Test is running, debug_wb_pc = 0xbfc72330
          [ 802000 ns] Test is running, debug_wb_pc = 0xbfc739a4
          [ 812000 ns] Test is running, debug_wb_pc = 0xbfc74fb4
  ----[ 818185 ns] Number 8'd39 Functional Test Point PASS!!!
          [ 822000 ns] Test is running, debug_wb_pc = 0xbfc52974
          [ 832000 ns] Test is running, debug_wb_pc = 0xbfc53da4
          [ 842000 ns] Test is running, debug_wb_pc = 0xbfc55284
  ----[ 847865 ns] Number 8'd40 Functional Test Point PASS!!!
          [ 852000 ns] Test is running, debug_wb_pc = 0xbfc29274
          [ 862000 ns] Test is running, debug_wb_pc = 0xbfc2a630
          [ 872000 ns] Test is running, debug_wb_pc = 0xbfc2b9d0
          [ 882000 ns] Test is running, debug_wb_pc = 0xbfc2cdb0
          [ 892000 ns] Test is running, debug_wb_pc = 0xbfc2e1cc
  ----[ 892115 ns] Number 8'd41 Functional Test Point PASS!!!
          [ 902000 ns] Test is running, debug_wb_pc = 0xbfc197bc
          [ 912000 ns] Test is running, debug_wb_pc = 0xbfc1abe8
          [ 922000 ns] Test is running, debug_wb_pc = 0xbfc1bf50
          [ 932000 ns] Test is running, debug_wb_pc = 0xbfc1d328
  ----[ 938395 ns] Number 8'd42 Functional Test Point PASS!!!
          [ 942000 ns] Test is running, debug_wb_pc = 0xbfc11860
          [ 952000 ns] Test is running, debug_wb_pc = 0xbfc129c0
          [ 962000 ns] Test is running, debug_wb_pc = 0xbfc13b20
          [ 972000 ns] Test is running, debug_wb_pc = 0xbfc14c80
          [ 982000 ns] Test is running, debug_wb_pc = 0xbfc15dec
  ----[ 989145 ns] Number 8'd43 Functional Test Point PASS!!!
          [ 992000 ns] Test is running, debug_wb_pc = 0x00000000
          [1002000 ns] Test is running, debug_wb_pc = 0x00000000
          [1012000 ns] Test is running, debug_wb_pc = 0xbfc7e1dc
          [1022000 ns] Test is running, debug_wb_pc = 0x00000000
          [1032000 ns] Test is running, debug_wb_pc = 0xbfc7eab0
          [1042000 ns] Test is running, debug_wb_pc = 0x00000000
  ----[1049215 ns] Number 8'd44 Functional Test Point PASS!!!
          [1052000 ns] Test is running, debug_wb_pc = 0xbfc0ecec
          [1062000 ns] Test is running, debug_wb_pc = 0x00000000
          [1072000 ns] Test is running, debug_wb_pc = 0xbfc0f5c0
          [1082000 ns] Test is running, debug_wb_pc = 0x00000000
          [1092000 ns] Test is running, debug_wb_pc = 0x00000000
          [1102000 ns] Test is running, debug_wb_pc = 0x00000000
          [1112000 ns] Test is running, debug_wb_pc = 0x00000000
          [1122000 ns] Test is running, debug_wb_pc = 0xbfc10c18
          [1132000 ns] Test is running, debug_wb_pc = 0x00000000
  ----[1136645 ns] Number 8'd45 Functional Test Point PASS!!!
          [1142000 ns] Test is running, debug_wb_pc = 0xbfc3511c
          [1152000 ns] Test is running, debug_wb_pc = 0xbfc360bc
  ----[1160185 ns] Number 8'd46 Functional Test Point PASS!!!
          [1162000 ns] Test is running, debug_wb_pc = 0xbfc81ba4
          [1172000 ns] Test is running, debug_wb_pc = 0xbfc82b44
  ----[1181485 ns] Number 8'd47 Functional Test Point PASS!!!
          [1182000 ns] Test is running, debug_wb_pc = 0xbfc8842c
  ----[1191015 ns] Number 8'd48 Functional Test Point PASS!!!
          [1192000 ns] Test is running, debug_wb_pc = 0xbfc17718
  ----[1200525 ns] Number 8'd49 Functional Test Point PASS!!!
          [1202000 ns] Test is running, debug_wb_pc = 0xbfc6039c
  ----[1209415 ns] Number 8'd50 Functional Test Point PASS!!!
          [1212000 ns] Test is running, debug_wb_pc = 0xbfc283e8
  ----[1214545 ns] Number 8'd51 Functional Test Point PASS!!!
  ----[1220525 ns] Number 8'd52 Functional Test Point PASS!!!
          [1222000 ns] Test is running, debug_wb_pc = 0xbfc00fb8
  ----[1227145 ns] Number 8'd53 Functional Test Point PASS!!!
          [1232000 ns] Test is running, debug_wb_pc = 0xbfc8ce70
  ----[1233445 ns] Number 8'd54 Functional Test Point PASS!!!
  ----[1240065 ns] Number 8'd55 Functional Test Point PASS!!!
          [1242000 ns] Test is running, debug_wb_pc = 0xbfc16d30
  ----[1247325 ns] Number 8'd56 Functional Test Point PASS!!!
          [1252000 ns] Test is running, debug_wb_pc = 0xbfc3a604
  ----[1253945 ns] Number 8'd57 Functional Test Point PASS!!!
  ----[1258815 ns] Number 8'd58 Functional Test Point PASS!!!
          [1262000 ns] Test is running, debug_wb_pc = 0xbfc37538
          [1272000 ns] Test is running, debug_wb_pc = 0xbfc38228
          [1282000 ns] Test is running, debug_wb_pc = 0xbfc38f68
  ----[1286575 ns] Number 8'd59 Functional Test Point PASS!!!
          [1292000 ns] Test is running, debug_wb_pc = 0xbfc67fb8
          [1302000 ns] Test is running, debug_wb_pc = 0xbfc68ca8
          [1312000 ns] Test is running, debug_wb_pc = 0x00000000
  ----[1316285 ns] Number 8'd60 Functional Test Point PASS!!!
          [1322000 ns] Test is running, debug_wb_pc = 0x00000000
          [1332000 ns] Test is running, debug_wb_pc = 0xbfc2f684
  ----[1338095 ns] Number 8'd61 Functional Test Point PASS!!!
          [1342000 ns] Test is running, debug_wb_pc = 0xbfc4ae98
          [1352000 ns] Test is running, debug_wb_pc = 0xbfc4bba4
          [1362000 ns] Test is running, debug_wb_pc = 0x00000000
  ----[1362885 ns] Number 8'd62 Functional Test Point PASS!!!
          [1372000 ns] Test is running, debug_wb_pc = 0xbfc44cac
          [1382000 ns] Test is running, debug_wb_pc = 0xbfc45a3c
          [1392000 ns] Test is running, debug_wb_pc = 0xbfc4677c
  ----[1393875 ns] Number 8'd63 Functional Test Point PASS!!!
          [1402000 ns] Test is running, debug_wb_pc = 0xbfc308e0
          [1412000 ns] Test is running, debug_wb_pc = 0xbfc31664
          [1422000 ns] Test is running, debug_wb_pc = 0xbfc323c0
  ----[1423075 ns] Number 8'd64 Functional Test Point PASS!!!
  ```
  
  
