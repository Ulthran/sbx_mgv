try:
    BENCHMARK_FP
except NameError:
    BENCHMARK_FP = output_subdir(Cfg, "benchmarks")
try:
    LOG_FP
except NameError:
    LOG_FP = output_subdir(Cfg, "logs")
try:
    VIRUS_FP
except NameError:
    VIRUS_FP = Cfg["all"]["output_fp"] / "virus"


def get_mgv_ext_path() -> Path:
    ext_path = Path(sunbeam_dir) / "extensions" / "sbx_mgv"
    if ext_path.exists():
        return ext_path
    raise Error(
        "Filepath for MGV not found, are you sure it's installed under extensions/sbx_mgv?"
    )


def get_mgv_db_path() -> Path:
    ext_path = get_mgv_ext_path()
    return ext_path / "MGV" / "viral_detection_pipeline" / "input"


localrules:
    all_mgv,


rule all_mgv:
    input:
        expand(VIRUS_FP / "mgv" / "{sample}" / "viral_contigs.tsv", sample=Samples.keys()),


rule install_mgv:
    output:
        installed=VIRUS_FP / "mgv" / ".installed",
    params:
        ext_path=get_mgv_ext_path(),
    shell:
        """
        cd {params.ext_path}
        if [ ! -d MGV ]; then
            echo "Installing MGV"
            git clone https://github.com/snayfach/MGV.git
        fi

        touch {output.installed}
        """
    

rule install_mgv_dbs:
    input:
        VIRUS_FP / "mgv" / ".installed",
    output:
        imgvr=get_mgv_db_path() / "imgvr.hmm",
        pfam=get_mgv_db_path() / "pfam.hmm",
    params:
        ext_path=get_mgv_ext_path(),
    shell:
        """
        cd {params.ext_path}
        cd MGV/viral_detection_pipeline/

        if ! [ -f input/imgvr.hmm ]; then
            wget -O input/imgvr.hmm.gz https://img.jgi.doe.gov//docs/final_list.hmms.gz
            gunzip input/imgvr.hmm.gz
        fi
        if ! [ -f input/pfam.hmm ]; then
            wget -O input/pfam.hmm.gz ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam31.0/Pfam-A.hmm.gz
            gunzip input/pfam.hmm.gz
        fi
        """


# This relies on the first rule from sbx_virus_id -_-
rule mgv_prodigal:
    input:
        contigs=ASSEMBLY_FP / "virus_id_megahit" / "{sample}_asm" / "final.contigs.fa",
        installed=VIRUS_FP / "mgv" / ".installed",
    output:
        fna=VIRUS_FP / "mgv" / "{sample}" / "{sample}.fna",
        faa=VIRUS_FP / "mgv" / "{sample}" / "{sample}.faa",
        ffn=VIRUS_FP / "mgv" / "{sample}" / "{sample}.ffn",
        gff=VIRUS_FP / "mgv" / "{sample}" / "{sample}.gff",
    conda:
        "envs/mgv_env.yml"
    shell:
        """
        cp {input.contigs} {output.fna}
        prodigal -i {output.fna} -a {output.faa} -d {output.ffn} -p meta -f gff > {output.gff}
        """


rule mgv_hmmsearch_imgvr:
    input:
        faa=VIRUS_FP / "mgv" / "{sample}" / "{sample}.faa",
        imgvr=get_mgv_db_path() / "imgvr.hmm",
    output:
        hmmout=VIRUS_FP / "mgv" / "{sample}" / "imgvr.out",
    conda:
        "envs/mgv_env.yml"
    threads: 8
    shell:
        """
        hmmsearch -Z 1 --cpu {threads} --noali --tblout {output.hmmout} {input.imgvr} {input.faa}
        """


rule mgv_hmmsearch_pfam:
    input:
        faa=VIRUS_FP / "mgv" / "{sample}" / "{sample}.faa",
        pfam=get_mgv_db_path() / "pfam.hmm",
    output:
        hmmout=VIRUS_FP / "mgv" / "{sample}" / "pfam.out",
    conda:
        "envs/mgv_env.yml"
    threads: 8
    shell:
        """
        hmmsearch -Z 1 --cut_tc --cpu {threads} --noali --tblout {output.hmmout} {input.pfam} {input.faa}
        """


rule mgv_count_viral_gene_hits:
    input:
        contigs=VIRUS_FP / "mgv" / "{sample}" / "{sample}.fna",
        faa=VIRUS_FP / "mgv" / "{sample}" / "{sample}.faa",
        hmmout_imgvr=VIRUS_FP / "mgv" / "{sample}" / "imgvr.out",
        hmmout_pfam=VIRUS_FP / "mgv" / "{sample}" / "pfam.out",
    output:
        tsv=VIRUS_FP / "mgv" / "{sample}" / "hmm_hits.tsv",
    params:
        fp=str(get_mgv_ext_path() / "MGV" / "viral_detection_pipeline"),
    conda:
        "envs/mgv_env.yml"
    shell:
        """
        cd {params.fp}
        python count_hmm_hits.py {input.contigs} {input.faa} {input.hmmout_imgvr} {input.hmmout_pfam} > {output.tsv}
        """


rule mgv_virfinder:
    input:
        contigs=VIRUS_FP / "mgv" / "{sample}" / "{sample}.fna",
    output:
        tsv=VIRUS_FP / "mgv" / "{sample}" / "virfinder.tsv",
    params:
        fp=str(get_mgv_ext_path() / "MGV" / "viral_detection_pipeline"),
    conda:
        "envs/virfinder_env.yml"
    shell:
        """
        cd {params.fp}
        Rscript virfinder.R {input.contigs} {output.tsv}
        """


rule mgv_strand_switch:
    input:
        contigs=VIRUS_FP / "mgv" / "{sample}" / "{sample}.fna",
        faa=VIRUS_FP / "mgv" / "{sample}" / "{sample}.faa",
    output:
        tsv=VIRUS_FP / "mgv" / "{sample}" / "strand_switch.tsv",
    params:
        fp=str(get_mgv_ext_path() / "MGV" / "viral_detection_pipeline"),
    conda:
        "envs/mgv_env.yml"
    shell:
        """
        cd {params.fp}
        python strand_switch.py {input.contigs} {input.faa} > {output.tsv}
        """


rule mgv_master_table:
    input:
        hmm=VIRUS_FP / "mgv" / "{sample}" / "hmm_hits.tsv",
        virfinder=VIRUS_FP / "mgv" / "{sample}" / "virfinder.tsv",
        strand_switch=VIRUS_FP / "mgv" / "{sample}" / "strand_switch.tsv",
    output:
        tsv=VIRUS_FP / "mgv" / "{sample}" / "master_table.tsv",
    params:
        fp=str(get_mgv_ext_path() / "MGV" / "viral_detection_pipeline"),
    conda:
        "envs/mgv_env.yml"
    shell:
        """
        cd {params.fp}
        python master_table.py {input.hmm} {input.virfinder} {input.strand_switch} > {output.tsv}
        """


rule mgv_predict_viral_contigs:
    input:
        mt=VIRUS_FP / "mgv" / "{sample}" / "master_table.tsv",
    output:
        tsv=VIRUS_FP / "mgv" / "{sample}" / "viral_contigs.tsv",
    params:
        fp=str(get_mgv_ext_path() / "MGV" / "viral_detection_pipeline"),
        in_base=str(VIRUS_FP / "mgv" / "{sample}"),
        out_base=str(VIRUS_FP / "mgv" / "{sample}"),
    conda:
        "envs/mgv_env.yml"
    shell:
        """
        cd {params.fp}
        python viral_classify.py --features {input.mt} --in_base {params.in_base} --out_base {params.out_base}
        """
