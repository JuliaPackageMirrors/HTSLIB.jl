@enum htsFormatCategory unknown_category sequence_data variant_data index_file region_list category_maximum=32767
@enum htsExactFormat unknown_format binary_format text_format sam bam bai cram crai vcf bcf csi gzi tbi bed format_maximum=32767
@enum htsCompression no_compression gzip bgzf custom compression_maximum=32767

immutable Record
    tid::Int32 # chromosome ID defined by bam_hdr_t
    pos::Int32 # 0-based leftmost coordinate
    bin::UInt16 # bin calculated by bam_reg2bin
    qual::UInt8 # mapping quality
    l_qname::UInt8 #length of the query name
    flag::UInt16 # bitwise flag
    n_cigar::UInt16 # number of CIGAR operations
    l_qseq::Int32 # length of the query sequence (read)
    mtid::Int32 # chrosome ID of next read in template
    mpos::Int32 # 0-based of next read in template, defined by bam_hdr_t
    isize::Int32 # ??? template length ???
    
    l_data::Int32 #current length of data
    m_data::Int32 # maximum length of data
    data::Ptr{Cuchar} # qname-cigar-seq-qual-aux how to load them all?
    id::UInt64   # BAM_ID ???
end

type KString
    l::Csize_t #8
    m::Csize_t #8
    s::Ptr{Cchar} #8
    function KString(l,m,s)
        new(l,m,s)
    end
    function KString(str::ASCIIString)
        s = convert(Ptr{Cchar}, pointer(str.data))
        l = length(str)
        m = l
        KString(l,m,s)
    end
end

bitstype 32 BINS

type HTSFile
    bins::UInt32 
    lineno::Int64 

    l::Csize_t 
    m::Csize_t 
    s::Ptr{Cchar}
    
    fn::Ptr{Cchar}
    fn_aux::Ptr{Cchar}
    bgzf::Ptr{Void}

    category::htsFormatCategory
    format::htsExactFormat

    major::Cshort
    minor::Cshort
    
    compression_level::Cshort
    specific::Ptr{Void}
end

#typealias Header Void
#=
 @abstract Structure for the alignment header.
 @field n_targets   number of reference sequences
 @field l_text      length of the plain text in the header
 @field target_len  lengths of the reference sequences
 @field target_name names of the reference sequences
 @field text        plain text
 @field sdict       header dictionary
=#
type Header
    n_targets::Int32  
    ignore_sam_err::Int32
    l_text::UInt32
    target_len::Ptr{UInt32}
    cigar_tab::Ptr{Int8}
    target_name::Ptr{Ptr{Cchar}}
    text::Ptr{Cchar}
    sdict::Ptr{Void}
end

function strptr(phdr::Ptr{Header})
    hdr = unsafe_load(phdr)
    text = convert(Ptr{UInt8}, hdr.text)
    l_text = hdr.l_text
    strptr(text,1,hdr.l_text)
end

function strptr(pkstr::Ptr{KString})
    kstr = unsafe_load(pkstr)
    p = convert(Ptr{UInt8},kstr.s)
    strptr(p,1,kstr.l)
end
function show(io::IO,ks::KString)
    data = Array{UInt8,1}(ks.l)
    for i = 1:ks.l
        data[i] = unsafe_load(ks.s,i)
    end
    print(io,ASCIIString(data))
end

function bam_hdr_init()
    ccall((:bam_hdr_init,libhts),Ptr{Header},())
end
@doc """ input: BGZF *fp
         output: bam_hdr_t*
""" ->
function bam_hdr_read(bam_hdl::Ptr{Void})
    ccall((:bam_hdr_read,libhts),Ptr{Header},(Ptr{Void},),bam_hdl)
end
@doc """ input:  BGZF *fp
                 const bam_hdr_t *h
         output: int
""" ->
function bam_hdr_write(fp,h::Ptr{Header})
    ccall((:bam_hdr_write,libhts),Cint,(Ptr{Void},Ptr{Header}),fp,h)
end
@doc """ void bam_hdr_destroy(bam_hdr_t *h)
""" ->
function bam_hdr_destroy(h)
    ccall((:bam_hdr_destroy,libhts),Void,(Ptr{Header},),h)
end
@doc """ int bam_name2id(bam_hdr_t *h,const char*ref)
""" ->
function bam_name2id(h::Ptr{Void},ref::Ptr{Cchar})
    ccall((:bam_name2id,libhts),Cint,(Ptr{Void},Ptr{Cchar}),h,ref)
end
@doc """ bam_hdr_t* bam_hdr_dup(const bam_hdr_t *h0)
""" ->
function bam_hdr_dup(h0)
    ccall((:bam_hdr_dup,libhts),Ptr{Header},(Ptr{Header},),h)
end
@doc """ bam1_t* bam_init1(void)
""" ->
function bam_init1()
    ccall((:bam_init1,libhts),Ptr{Record},())
end
@doc """ void bam_destroy1(bam1_t *b)
""" ->
function bam_destroy1(b::Ptr{Record})
    ccall((:bam_destroy1,libhts),Void,(Ptr{Record},),b)
end
@doc """ int bam_read1(BGZF *fp, bam1_t *b)
""" ->
function bam_read!(fp,b)
    ccall((:bam_read1,libhts),Cint,(Ptr{Void},Ptr{Record}),fp,b)
end
@doc """ int bam_write1(BGZF *fp, const bam1_t *b)
""" ->
function bam_write1(fp,b)
    ccall((:bam_write1,libhts),Cint,(Ptr{Void},Ptr{Record}),fp,b)
end
@doc """ bam1_t *bam_copy1(bam1_t *bdst, const bam1_t *bsrc)
""" ->
function bam_copy(bdst,bsrc)
    ccall((:bam_copy1,libhts),Ptr{Record},(Ptr{Record},Ptr{Record}),bdst,bsrc)
end
@doc """ bam1_t *bam_dup1(const bam1_t *bsrc)
""" ->
function bam_dup(bsrc)
    ccall((:bam_dup1,libhts),Ptr{Record},(Ptr{Record},),bsrc)
end
@doc """ int bam_cigar2qlen(int n_cigar, const uint32_t *cigar)
""" ->
function bam_cigar2qlen(n_cigar::Cint,cigar::Ptr{UInt32})
    ccall((:bam_cigar2qlen,libhts),Ptr{Record},(Cint,Ptr{UInt32}),n_cigar,cigar)
end
@doc """ int bam_cigar2rlen(int n_cigar, const uint32_t *cigar)
""" ->
function bam_cigar2rlen(n_cigar::Cint,cigar::Ptr{UInt32})
    ccall((:bam_cigar2rlen,libhts),Ptr{Record},(Cint,Ptr{UInt32}),n_cigar,cigar)
end
@doc """ int32_t bam_endpos(const bam1_t *b)
""" ->
function bam_endpos(b)
    ccall((:bam_endpos,libhts),Int32,(Ptr{Record},),b)
end
@doc """ int bam_str2flag(const char *str)
""" ->
function bam_str2flag(str::Ptr{Cchar})
    ccall((:bam_str2flag,libhts),Cint,(Ptr{Cchar},),str)
end
@doc """ char *bam_flag2str(int flag)
""" ->
function bam_flag2str(flag::Cint)
    ccall((:bam_flag2str,libhts),Ptr{Cchar},(Cint,),flag)
end

##############################################
###      BAM/CRAM indexing                 ###
##############################################
#=
    // These BAM iterator functions work only on BAM files.  To work with either
    // BAM or CRAM files use the sam_index_load() & sam_itr_*() functions.
    #define bam_itr_destroy(iter) hts_itr_destroy(iter)
    #define bam_itr_queryi(idx, tid, beg, end) sam_itr_queryi(idx, tid, beg, end)
    #define bam_itr_querys(idx, hdr, region) sam_itr_querys(idx, hdr, region)
    #define bam_itr_next(htsfp, itr, r) hts_itr_next((htsfp)->fp.bgzf, (itr), (r), 0)
=#
@doc """ #define bam_itr_destroy(iter) hts_itr_destroy(iter)
         void hts_itr_destroy(hts_itr_t *iter)
""" ->
function bam_itr_destroy(iter) 
    ccall((:hts_itr_destroy,libhts),Void,(Ptr{Void},),iter)
end

@doc """ #define bam_itr_queryi(idx, tid, beg, end) sam_itr_queryi(idx, tid, beg, end)
         hts_itr_t *sam_itr_queryi(const hts_idx_t *idx, int tid, int beg, int end)
""" ->
function bam_itr_queryi(idx::Ptr{Void}, tid::Cint, beg::Cint, ed::Cint)
    ccall((:sam_itr_queryi,libhts), Ptr{Void},(Ptr{Void},Ptr{Cint},Ptr{Cint},Ptr{Cint}),(idx, tid, beg, ed))
end
@doc """ #define bam_itr_querys(idx, hdr, region) sam_itr_querys(idx, hdr, region)
         hts_itr_t *sam_itr_querys(const hts_idx_t *idx, bam_hdr_t *hdr, const char *region)
""" ->
function bam_itr_querys(idx, hdr, region::Ptr{Cchar})
    ccall((:sam_itr_querys,libhts),Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Cchar}),idx, hdr, region)
end

@doc """ #define bam_itr_next(htsfp, itr, r) hts_itr_next((htsfp)->fp.bgzf, (itr), (r), 0)
         int hts_itr_next(BGZF *fp, hts_itr_t *iter, void *r, void *data)
""" ->
function bam_itr_next(bgzf, itr, r)
    ccall((:hts_itr_next,libhts),Cint,(Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),bgzf, itr, r, C_NULL)
end

@doc """
// build .csi or .bai BAM index file.  Does not work with CRAM.
// It is recommended to use the sam_index_* functions below instead.
#define bam_index_load(fn) hts_idx_load((fn), HTS_FMT_BAI)
hts_idx_t *hts_idx_load(const char *fn, int fmt);
""" ->
function bam_index_load(fn)
    ccall((:hts_idx_load,libhts),Ptr{Void},(Ptr{Cchar},Cint),fn,1)
end

@doc """
// build .csi or .bai BAM index file.  Does not work with CRAM.
// It is recommended to use the sam_index_* functions below instead.
#define bam_index_build(fn, min_shift) (sam_index_build((fn), (min_shift)))
int sam_index_build(const char *fn, int min_shift)
""" ->
function bam_index_build(fn, min_shift)
    ccall((:sam_index_build,libhts),Cint,(Ptr{Cchar},Cint),fn,min_shift)
end

@doc """
/// Load a BAM (.csi or .bai) or CRAM (.crai) index file
/** @param fp  File handle of the data file whose index is being opened
    @param fn  BAM/CRAM/etc filename to search alongside for the index file
    @return  The index, or NULL if an error occurred.
*/
hts_idx_t *sam_index_load(htsFile *fp, const char *fn);
""" ->
function sam_index_load(fp, fn::Ptr{Cchar})
    ccall((:sam_index_load,libhts),Ptr{Void},(Ptr{Void},Ptr{Cchar}),fp,fn)
end

@doc """
/// Load a specific BAM (.csi or .bai) or CRAM (.crai) index file
/** @param fp     File handle of the data file whose index is being opened
    @param fn     BAM/CRAM/etc data file filename
    @param fnidx  Index filename, or NULL to search alongside @a fn
    @return  The index, or NULL if an error occurred.
*/
hts_idx_t *sam_index_load2(htsFile *fp, const char *fn, const char *fnidx);
""" ->
function sam_index_load2(fp, fn::Ptr{Cchar}, fnidx::Ptr{Cchar});
    ccall((:sam_index_load2,libhts), Ptr{Void},(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),fp,fn,fnidx)
end
@doc """
/// Generate and save an index file
/** @param fn        Input BAM/etc filename, to which .csi/etc will be added
    @param min_shift Positive to generate CSI, or 0 to generate BAI
    @return  0 if successful, or negative if an error occurred (usually -1; or
             -2: opening fn failed; -3: format not indexable)
*/
int sam_index_build(const char *fn, int min_shift);
""" ->
function sam_index_build(fn::Ptr{Cchar}, min_shift::Cint);
    ccall((:sam_index_build,libhts),Cint,(Ptr{Cchar},Cint),fn,  min_shift)
end
@doc """
/// Generate and save an index to a specific file
/** @param fn        Input BAM/CRAM/etc filename
    @param fnidx     Output filename, or NULL to add .bai/.csi/etc to @a fn
    @param min_shift Positive to generate CSI, or 0 to generate BAI
    @return  0 if successful, or negative if an error occurred.
*/
int sam_index_build2(const char *fn, const char *fnidx, int min_shift);
""" ->
function sam_index_build2(fn::Ptr{Cchar}, fnidx::Ptr{Cchar}, min_shift::Cint)
    ccall((:sam_index_build2,libhts),Cint,(Ptr{Cchar},Ptr{Cchar},Cint),fn, fnidx, min_shift)
end
@doc """
    #define sam_itr_destroy(iter) hts_itr_destroy(iter)
    void hts_itr_destroy(hts_itr_t *iter)
""" ->
function sam_itr_destroy(iter)
    ccall((:hts_itr_destroy,libhts),Void,(Ptr{Void},),iter)
end

@doc """    hts_itr_t *sam_itr_queryi(const hts_idx_t *idx, int tid, int beg, int end);
""" ->
function sam_itr_queryi(idx, tid, beg, ed);
    ccall((:sam_itr_queryi,libhts),Ptr{Void},(Ptr{Void},Cint,Cint,Cint), idx, tid, beg, ed)
end
@doc """
    hts_itr_t *sam_itr_querys(const hts_idx_t *idx, bam_hdr_t *hdr, const char *region);
""" ->
function sam_itr_querys(idx, hdr::Ptr{Header}, region::Ptr{Cchar})
    ccall((:sam_itr_querys,libhts),Ptr{Void},(Ptr{Void},Ptr{Header},Ptr{Cchar}),idx, hdr, region)
end
@doc """
    #define sam_itr_next(htsfp, itr, r) hts_itr_next((htsfp)->fp.bgzf, (itr), (r), (htsfp))
    int hts_itr_next(BGZF *fp, hts_itr_t *iter, void *r, void *data)
""" ->
function sam_itr_next(bgzf, itr, r,handle)
    ccall((:hts_itr_next,libhts),Cint,(Ptr{Void},Ptr{Void},Ptr{Record},Ptr{Void}),bgzf,itr,r,handle)
end

#=
    /***************
     *** SAM I/O ***
     ***************/
=#
#=
@doc """
    #define sam_open(fn, mode) (hts_open((fn), (mode)))
    htsFile *hts_open(const char *fn, const char *mode)        
""" ->
sam_open(fn::AbstractString,mode::AbstractString) = hts_open(fn,mode)
=#
@doc """
    #define sam_open_format(fn, mode, fmt) (hts_open_format((fn), (mode), (fmt)))
    htsFile *hts_open_format(const char *fn, const char *mode, const htsFormat *fmt);        
""" ->
function sam_open_format(fn::Ptr{Cchar}, mode::Ptr{Cchar}, fmt)
    ccall((:hts_open_format,libhts),Ptr{Void},(Ptr{Cchar},Ptr{Cchar},Ptr{Void}),fn, mode, fmt)
end
@doc """
    #define sam_close(fp) hts_close(fp)
    int hts_close(htsFile *fp)    
""" ->
function sam_close(fp)
    ret = ccall((:hts_close,libhts),Cint,(Ptr{Void},),fp)
    @assert ret == 0 || info("non-zeros status in the sam_close")
end
@doc """
    int sam_open_mode(char *mode, const char *fn, const char *format);
""" ->
function sam_open_mode(mode::Ptr{Cchar}, fn::Ptr{Cchar}, format::Ptr{Cchar});
    ccall((:sam_open_mode,libhts),Cint,(Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}), mode, fn, format)
end
@doc """
    // A version of sam_open_mode that can handle ,key=value options.
    // The format string is allocated and returned, to be freed by the caller.
    // Prefix should be "r" or "w",
    char *sam_open_mode_opts(const char *fn,
                             const char *mode,
                             const char *format);
""" ->
function sam_open_mode_opts(fn::Ptr{Cchar},mode::Ptr{Cchar},format::Ptr{Cchar})
    ccall((:sam_open_mode_opts,libhts),Ptr{Cchar},(Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),fn,mode,format)
end

@doc """
    bam_hdr_t *sam_hdr_parse(int l_text, const char *text);
    translate a string to a bam_hdr_t type    
""" ->
function sam_hdr_parse(l_text::Cint, text::Cstring)
    phdr = ccall((:sam_hdr_parse,libhts),Ptr{Header},(Cint,Cstring),l_text,text)
end

@doc """
    bam_hdr_t *sam_hdr_read(samFile *fp);
""" ->
function sam_hdr_read(fp::Ptr{Void})
    ccall((:sam_hdr_read,libhts),Ptr{Header},(Ptr{Void},),fp)
end

@doc """
    int sam_hdr_write(samFile *fp, const bam_hdr_t *h);
""" ->
function sam_hdr_write(fp::Ptr{Void}, h::Ptr{Header})
    ccall((:sam_hdr_write,libhts),Cint,(Ptr{Void},Ptr{Header}),fp,h)
end
@doc """
    int sam_parse1(kstring_t *s, bam_hdr_t *h, bam1_t *b);
""" ->
function sam_parse1(s::Ptr{KString}, h::Ptr{Header}, b::Ptr{Record})
    ccall((:sam_parse1,libhts),Cint,(Ptr{KString},Ptr{Header},Ptr{Record}), s, h, b)
end
@doc """
        int sam_format1(const bam_hdr_t *h, const bam1_t *b, kstring_t *str);
""" ->
function sam_format1(h::Ptr{Header}, b::Ptr{Record}, str::Ptr{KString})
    ccall((:sam_format1,libhts),Cint,(Ptr{Header},Ptr{Record},Ptr{KString}), h, b, str)
end
@doc """
    int sam_read1(samFile *fp, bam_hdr_t *h, bam1_t *b);
""" ->
function sam_read1(fp, h::Ptr{Header}, b::Ptr{Record})
    ccall((:sam_read1,libhts),Cint,(Ptr{Void},Ptr{Header},Ptr{Record}), fp, h,b)
end
@doc """
    int sam_write1(samFile *fp, const bam_hdr_t *h, const bam1_t *b);
""" ->
function sam_write1(fp, h::Ptr{Header}, b::Ptr{Record})
    ccall((:sam_write1,libhts),Cint,(Ptr{Void},Ptr{Header},Ptr{Record}),fp, h, b)
end

#=
    /*************************************
     *** Manipulating auxiliary fields ***
     *************************************/
=#
@doc """
    uint8_t *bam_aux_get(const bam1_t *b, const char tag[2]);
""" ->
function bam_aux_get(b,tag::Ptr{Cchar})
    ccall((:bam_aux_get,libhts),UInt8,(Ptr{Void},Ptr{Cchar}), b, tag)
end
@doc """
    int32_t bam_aux2i(const uint8_t *s);
""" ->
function bam_aux2i(s::Ptr{UInt8})
    ccall((:bam_aux2i,libhts),Int32,(Ptr{UInt8},),s)
end
@doc """
    double bam_aux2f(const uint8_t *s);
""" ->
function bam_aux2f(s::Ptr{UInt8})
    ccall((:bam_aux2f,libhts),Cdouble,(Ptr{UInt8},),s)
end
@doc """
    char bam_aux2A(const uint8_t *s);
""" ->
function bam_aux2A(s::Ptr{UInt8})
    ccall((:bam_aux2A,libhts),Cchar,(Ptr{UInt8},),s)
end
@doc """
    char *bam_aux2Z(const uint8_t *s);
""" ->
function bam_aux2Z(s::Ptr{UInt8})
    ccall((:bam_aux2Z,libhts),Ptr{Cchar},(Ptr{UInt8},),s)
end
@doc """
    void bam_aux_append(bam1_t *b, const char tag[2], char type, int len, uint8_t *data);
""" ->
function bam_aux_append(b::Ptr{Record}, tag::Ptr{Cchar}, tp::Cchar, len::Cint, data::Ptr{UInt8})
    warn("Not sure how to deal with char tag[2]")
    ccall((:bam_aux_append,libhts),Void,(Ptr{Record},Ptr{Char},Cchar,Cint,UInt8), b, tag, tp, len, data)
end

@doc """
    int bam_aux_del(bam1_t *b, uint8_t *s);
""" ->
function bam_aux_del(b::Ptr{Record}, s::Ptr{UInt8})
    ccall((:bam_aux_del,libhts),Cint,(Ptr{Record},Ptr{UInt8}),b, s)
end

function bam_get_cigar(rec::Record)
    n_cigar = rec.n_cigar
    p = convert(Ptr{UInt32}, (rec.data + rec.l_qname))
    s = ""
    for i in 1:n_cigar
        tmp = unsafe_load(p,i)
        l4 = tmp & 0b1111
        h28 = tmp >> 4
        s = string(s,h28,cigarstring[l4+1])
    end
    s
end
function bam_seqi(s,i)
    (unsafe_load(s,(i-1)>>1+1) >> ((~(i-1)&1)<<2)) & 0xf
end
function bam_get_seq(rec::Record)
    pseq = rec.data + rec.n_cigar<<2 + rec.l_qname
    s = ""
    for i in 1:rec.l_qseq
        s =string(s, seq_nt16_str[bam_seqi(pseq, i)+1])
    end
    s
end
function bam_get_qual(rec::Record)
    len_qual = (rec.l_qseq+1)>>1
    p = rec.data + rec.n_cigar<<2 + rec.l_qname + (rec.l_qseq+1)>>1
    data = Array{UInt8,1}(len_qual)
    for i = 1:len_qual
        data[i] = unsafe_load(p,i) + 33
    end
    ASCIIString(data)
end
function bam_get_l_aux(rec::Record)
    p = rec.l_data - rec.n_cigar<<2 - rec.l_qname - rec.l_qseq - (rec.l_qseq + 1)>>1
end
function bam_get_aux(rec::Record)
    p = rec.data + rec.n_cigar<<2 + rec.l_qname + (rec.l_qseq+1)>>1 + rec.l_qseq
    len_aux = bam_get_l_aux(rec)
    data = Array{UInt8,1}(len_aux)
    for i = 1:len_aux
        data[i] = unsafe_load(p,i)
    end
    ASCIIString(data)
end

function hts_open{T<:AbstractString}(fn::T,mode::T)
    fp = pointer(fn.data)
    mdp = pointer(mode.data)
    ret = ccall((:hts_open,libhts),Ptr{Void},(Ptr{Cchar},Ptr{Cchar}),fp,mdp)
    if ret == C_NULL
        error("hts_open return C_NULL")
    end
    ret
end

function sam_read!(bam_hdl::Ptr{Void},bam_hdr_hdl::Ptr{Header},b::Ptr{Record})
    ccall((:sam_read1,libhts),Cint,(Ptr{Void},Ptr{Header},Ptr{Record}),bam_hdl,bam_hdr_hdl,b)
end

function sam_format!(h::Ptr{Header},b::Ptr{Record},pstr::Ptr{KString})
    ccall((:sam_format1,libhts),Cint,(Ptr{Header},Ptr{Record},Ptr{KString}),h,b,pstr)
end
function sam_parse!(pks,h,b)
    ccall((:sam_parse1,libhts),Cint,(Ptr{KString},Ptr{Void},Ptr{Record}),pks,h,b)
end

