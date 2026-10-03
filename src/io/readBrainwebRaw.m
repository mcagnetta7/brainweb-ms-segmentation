function volume = readBrainwebRaw(filePath, volumeSize, precision, byteOrder)
%READBRAINWEBRAW Legge un file raw BrainWeb e restituisce il volume 3D.
%
%   volume = READBRAINWEBRAW(filePath, volumeSize, precision, byteOrder)
%   legge il file raw indicato, ne verifica la struttura e restituisce un
%   volume di dimensioni volumeSize con i valori originali memorizzati.
%
%   Input:
%     filePath    percorso del file raw (aperto in sola lettura)
%     volumeSize  dimensioni [X Y Z] del volume
%     precision   tipo dei campioni: "uint8" oppure "uint16"
%     byteOrder   ordine dei byte: "ieee-le" oppure "ieee-be"
%
%   Output:
%     volume      array volumeSize della classe precision, con la
%                 convenzione V(i,j,k), i = X, j = Y, k = Z
%
%   Nel file X varia più velocemente e Z più lentamente: in MATLAB
%   (column-major) basta quindi un reshape, senza permute.
%
%   Nessuna elaborazione dei valori: niente riscalamento, normalizzazione
%   o conversione di tipo.

    arguments
        filePath {mustBeTextScalar}
        volumeSize (1,3) double {mustBeInteger, mustBePositive}
        precision {mustBeTextScalar, mustBeMember(precision, ["uint8", "uint16"])}
        byteOrder {mustBeTextScalar, mustBeMember(byteOrder, ["ieee-le", "ieee-be"])}
    end

    filePath = char(filePath);
    precision = char(precision);
    byteOrder = char(byteOrder);

    if ~isfile(filePath)
        error('brainweb:fileNotFound', ...
            'BrainWeb file not found: %s', filePath);
    end

    switch precision
        case 'uint8'
            bytesPerSample = 1;
        case 'uint16'
            bytesPerSample = 2;
    end

    nSamples = prod(volumeSize);
    expectedBytes = nSamples * bytesPerSample;

    fileInfo = dir(filePath);
    if fileInfo.bytes ~= expectedBytes
        error('brainweb:wrongFileSize', ...
            ['File size of %s is %d bytes, expected %d ' ...
             '(%d samples x %d bytes).'], ...
            filePath, fileInfo.bytes, expectedBytes, nSamples, bytesPerSample);
    end

    [fid, openMessage] = fopen(filePath, 'r', byteOrder);
    if fid < 0
        error('brainweb:openFailed', ...
            'Cannot open %s: %s', filePath, openMessage);
    end
    closeFile = onCleanup(@() fclose(fid));

    [data, count] = fread(fid, nSamples, [precision '=>' precision]);
    if count ~= nSamples
        error('brainweb:incompleteRead', ...
            'Read %d samples from %s, expected %d.', count, filePath, nSamples);
    end

    [~, extraCount] = fread(fid, 1, precision);
    if extraCount ~= 0
        error('brainweb:unexpectedData', ...
            'File %s contains data beyond the expected %d samples.', ...
            filePath, nSamples);
    end

    volume = reshape(data, volumeSize);

end
