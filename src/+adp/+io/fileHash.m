function digest = fileHash(path)
%FILEHASH SHA-256 of file bytes using the standard MATLAB JVM.
    fid = fopen(path,'rb');
    if fid < 0, error('adp:io:ReadFailed','Cannot read file: %s',path); end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    engine = java.security.MessageDigest.getInstance('SHA-256');
    while ~feof(fid)
        bytes = fread(fid,1024*1024,'*uint8');
        if ~isempty(bytes), engine.update(typecast(bytes,'int8')); end
    end
    digest = lower(reshape(dec2hex(typecast(engine.digest(),'uint8'),2).',1,[]));
end
