{
  ...
}: {
  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit (tpkgs)
        collection-basic
        collection-latex
        collection-latexextra
        collection-fontsrecommended
        collection-langchinese
        collection-bibtexextra
        # collection-science
        collection-pictures
        collection-publishers;

      inherit (tpkgs) latexindent;

      # 核心中文 + 现代排版（xe/lua 引擎）
      inherit (tpkgs) ctex fontspec xecjk;

      # 画图 / 体系结构框图 / 流水线 / 缓存结构 / 时序图 必备
      inherit (tpkgs)
        pgf         # 最核心画图宏包
        pgfplots    # 数据图表（性能曲线、bar chart 常用）
        circuitikz  # 电路符号（偶尔画简单处理器结构有用）
        tikz-cd     #  commutative diagrams（数据通路、总线结构）
        tikz-qtree; # 树结构（缓存树、BHT、预测器树）

      # 伪代码 / 算法 / 体系结构描述常用
      inherit (tpkgs) algorithm2e algpseudocodex algorithmicx algorithms;

      # 代码高亮（Verilog / VHDL / C / asm 片段）
      inherit (tpkgs)
        minted    # 最美观（需 --shell-escape）
        listings  # minted 报错时的备选
        xcolor;   # listings / minted 依赖

      # 计量、单位、数值表格（性能数据、功耗、面积、频率…）
      inherit (tpkgs)
        siunitx   # 强烈推荐！
        numprint; # siunitx 补充

      # 其他体系结构论文高频
      inherit (tpkgs)
        ieeeconf                    # IEEE 会议/期刊模板常用类
        subfiles                    # 大论文分章节编译利器
        standalone                  # 单独编译 tikz 图片非常方便
        lipsum blindtext            # 调试占位文本
        enumitem parskip microtype  # 排版美化三件套
        acmart;                     # ACM 会议/期刊模板常用类

      # 优质论文模板
      inherit (tpkgs)
        njuthesis;                  # 南大
    };
  };
}

