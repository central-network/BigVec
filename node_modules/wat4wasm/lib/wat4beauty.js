function wat4beauty(watContent, alignIndentsWith = "\t", exportPadStart = 90) {

    function alignIndents(watContent) {
        let depth = 0;
        const TAB = alignIndentsWith || "\t";
        return watContent
            .split("\n")
            .map(line => {
                const trimmed = line.trim();
                if (!trimmed) return "";

                // --- 1. Adım: Hesaplama için "Temiz" Satırı Oluştur ---
                // Yorumları (;;) ve tırnak içindeki stringleri ("...") geçici olarak siliyoruz.
                // Bu sayede yorumdaki veya stringdeki parantezler sayımı bozmaz.
                let cleanLine = trimmed
                    .replace(/;;.*/g, "")         // Yorumları sil
                    .replace(/"[^"]*"/g, '""');   // String içlerini boşalt

                // --- 2. Adım: Parantez Bakiyesini Hesapla ---
                const openCount = (cleanLine.match(/\(/g) || []).length;
                const closeCount = (cleanLine.match(/\)/g) || []).length;

                // Satırın BAŞINDAKİ kapanış parantezlerini say (Örn: "))" ile başlıyorsa)
                // Bu, o satırın kendisini geri çekmek için lazım.
                let leadingCloseCount = 0;
                for (let char of cleanLine) {
                    if (char === ')') leadingCloseCount++;
                    else if (char === '(') break; // Açılış gelirse dur
                    else if (char === ' ') continue; // Boşlukları atla
                    else break; // Başka karakter gelirse dur
                }

                // --- 3. Adım: O anki satırı bas ---
                // Satırın kendi seviyesi = Mevcut Derinlik - Başlangıçtaki Kapanışlar
                let printDepth = Math.max(0, depth - leadingCloseCount);
                const indentation = TAB.repeat(printDepth);

                // --- 4. Adım: Gelecek satır için derinliği güncelle ---
                // Net değişim = Açılan - Kapanan
                // NOT: Senin istediğin "aynı satırda açılıp kapananlar" burada otomatik olarak
                // birbirini götürür (1 - 1 = 0) ve derinliği değiştirmez.
                depth += (openCount - closeCount);

                return `${indentation}${trimmed}`;
            })
            .join("\n");
    };

    function alignGlobals(watContent) {
        const lines = watContent.split("\n");
        const globalUpdates = []; // Hangi satırların global olduğunu tutacağız
        let maxNameLength = 0;

        // --- 1. TUR: Keşif ---
        // Tüm satırları gez, globalleri bul ve en uzun ismi ölç.
        lines.forEach((line, index) => {
            // Regex Açıklaması:
            // ^(\s*\(global\s+) -> Grup 1: Girinti + "(global " kelimesi
            // (\S+)             -> Grup 2: Global ismi (boşluk olmayan her şey)
            // \s+               -> İsimden sonraki (atılacak) boşluklar
            // (.*)$             -> Grup 3: Satırın geri kalanı (tip tanımları vs.)
            const match = line.match(/^(\s*\(global\s+)(\S+)\s+(.*)$/);

            if (match) {
                const name = match[2];
                if (name.length > maxNameLength) {
                    maxNameLength = name.length;
                }

                // Bu satırı ve parçalarını daha sonra kullanmak üzere sakla
                globalUpdates.push({
                    index: index,
                    prefix: match[1], // "  (global " kısmı
                    name: name,       // "$self.Object" kısmı
                    rest: match[3]    // "(mut externref)..." kısmı
                });
            }
        });

        // Kural 2: En uzun isme 1 ekle (Minimum boşluk garantisi)
        const alignLength = maxNameLength + 1;

        // --- 2. TUR: Uygulama ---
        // Sadece global satırlarını güncelle
        globalUpdates.forEach(update => {
            // Kural 3: İsim uzunluğunu bul ve aradaki boşluğu hesapla
            const currentNameLength = update.name.length;

            // Hedef uzunluktan ismin uzunluğunu çıkar
            const spacesNeeded = alignLength - currentNameLength;

            // Boşluk stringini oluştur
            const padding = " ".repeat(Math.max(1, spacesNeeded));

            // Parçaları birleştir: Prefix + İsim + Yeni Boşluklar + Geri Kalan
            // Not: update.rest'i trim() yapıyoruz ki, eski düzensiz boşluklar gitsin.
            const newLine = `${update.prefix}${update.name}${padding}${update.rest.trim()}`;

            // Orijinal satırı güncelle
            lines[update.index] = newLine;
        });

        return lines.join("\n");
    };

    function alignImports(watContent) {
        const lines = watContent.split("\n");
        const importUpdates = [];
        let maxDefLength = 0;

        lines.forEach((line, index) => {
            // Regex Açıklaması:
            // ^(\s*\(import\s+)        -> Grup 1: Girinti + "(import "
            // ("[^"]*"\s+"[^"]*")      -> Grup 2: İki string bloğu (Modül ve İsim) - Burası ölçülecek
            // (.*)$                    -> Grup 3: Satırın geri kalanı (imza, tip vb.)

            // Not: Bu regex tam senin dediğin gibi 1. tırnak ile 4. tırnak arasını (içindekilerle beraber) yakalar.
            const match = line.match(/^(\s*\(import\s+)("[^"]*"\s+"[^"]*")(.*)$/);

            if (match) {
                const definitionPart = match[2]; // Örn: "env" "log"

                if (definitionPart.length > maxDefLength) {
                    maxDefLength = definitionPart.length;
                }

                importUpdates.push({
                    index: index,
                    prefix: match[1],      // "  (import "
                    definition: definitionPart,
                    rest: match[3]         // " (func $log...))"
                });
            }
        });

        // En uzun tanıma +1 ekleyerek hizalama sınırını belirle
        const alignTarget = maxDefLength + 1;

        // Hesaplanan boşluklarla satırları yeniden ör
        importUpdates.forEach(update => {
            const currentLen = update.definition.length;
            const paddingNeeded = alignTarget - currentLen;
            const padding = " ".repeat(Math.max(1, paddingNeeded));

            // Parçaları birleştir
            // update.rest.trim() yaparak imza kısmının başındaki düzensiz boşluğu atıyoruz.
            lines[update.index] = `${update.prefix}${update.definition}${padding}${update.rest.trim()}`;
        });

        return lines.join("\n");
    };

    function alignImportItemsPerfectly(watContent) {
        const lines = watContent.split("\n");
        const updates = [];
        let maxHeaderLength = 0; // "tip + isim" toplam uzunluğu için

        lines.forEach((line, index) => {
            // Regex Açıklaması:
            // ^(\s*\(import\s+.*\()    -> Grup 1: Prefix (parantez açılışına kadar)
            // (func|global|table|memory) -> Grup 2: TİP (keyword)
            // \s+                      -> Aradaki boşluk
            // (\$[^\s)]+)              -> Grup 3: İSİM ($variable)
            // (.*)$                    -> Grup 4: Geri kalan (Rest)
            const match = line.match(/^(\s*\(import\s+.*\()((?:func|global|table|memory))\s+(\$[^\s)]+)(.*)$/);

            if (match) {
                const type = match[2]; // örn: "func" veya "global"
                const name = match[3]; // örn: "$add"

                // Kritik Hesaplama: Tipin uzunluğu + 1 boşluk + İsmin uzunluğu
                // Bu bize "func $add" bloğunun toplam kapladığı yeri verir.
                const currentHeaderLength = type.length + 1 + name.length;

                if (currentHeaderLength > maxHeaderLength) {
                    maxHeaderLength = currentHeaderLength;
                }

                updates.push({
                    index: index,
                    prefix: match[1], // "  (import "mod" "item" ("
                    type: type,       // "func"
                    name: name,       // "$add"
                    headerLen: currentHeaderLength,
                    rest: match[4]    // " (param i32)..."
                });
            }
        });

        // En uzun başlığa 1 karakter güvenli boşluk ekle
        const alignTarget = maxHeaderLength + 1;

        updates.forEach(update => {
            // Ne kadar dolgu boşluğu lazım?
            // Hedef - Şu anki toplam uzunluk
            const paddingNeeded = alignTarget - update.headerLen;
            const padding = " ".repeat(Math.max(1, paddingNeeded));

            // Yeniden montaj:
            // Prefix + Tip + " " + İsim + HESAPLANAN_DOLGU + Geri Kalan
            lines[update.index] = `${update.prefix}${update.type} ${update.name}${padding}${update.rest.trim()}`;
        });

        return lines.join("\n");
    };

    function formatWatNearPerfectRestored(watContent) {

        const namableMatches = Array.from(
            watContent.matchAll(
                /\((param|local|type)\s+\$(.[^\s]*)\s+(.[^\s]*)\)/g
            )
        );

        const unNamedMatches = Array
            .from(
                watContent.matchAll(
                    /\((param|local|type|result)((\s(i32|f32|i64|f64|externref|funcref|v128))+)\)/g
                )
            )
            .filter(m => !namableMatches.some(a => a.index === m.index))
            .map(m => Object.defineProperties(m, { 3: { value: m[2] }, 2: { value: "" } }))
            ;

        const matches = namableMatches
            .concat(unNamedMatches)
            .sort((a, b) => b.index - a.index)
            ;

        const replace = new Array();
        let maxLineLength = -Infinity;

        matches
            .filter(m => {
                const wrapperFuncBegin = watContent.lastIndexOf("\n", watContent.lastIndexOf("(func", m.index));
                const wrapperNextEOL = watContent.indexOf("\n", wrapperFuncBegin);
                const wrapperFuncLine = watContent.substring(wrapperFuncBegin, wrapperNextEOL);

                return wrapperFuncLine.split("(").length !== wrapperFuncLine.split(")").length;
            })
            .forEach(match => {
                let [line, tag, name, kind] = match;

                const length = String(line).length;
                const begin = match.index;
                const end = begin + length;

                if (name.length > 0) {
                    name = `$${name} `
                }

                const lineLeft = `(${tag} ${name}`;
                const lineRight = ` ${kind})`;

                maxLineLength = Math.max(maxLineLength, length);
                replace.push({ begin, end, lineLeft, lineRight });
            });

        replace
            .forEach(({ begin, end, lineLeft, lineRight }) => {
                const padding = maxLineLength - (lineLeft.length + lineRight.length) + 1;
                const newLine = lineLeft.concat(" ".repeat(padding)).concat(lineRight);

                watContent = ""
                    .concat(watContent.substring(0, begin))
                    .concat(newLine)
                    .concat(watContent.substring(end))
                    ;
            });

        return watContent;
    };

    function alignExportsRight(watContent) {

        return watContent.split("\n").map(line => {
            // 1. Export tanımını yakala: (export "...")
            // Bu regex, tırnak içindeki kaçış karakterlerini (\") de güvenle atlar.
            const exportRegex = /\(export\s+"(?:[^"\\]|\\.)*"\)/;
            const match = line.match(exportRegex);

            // Eğer satırda export yoksa olduğu gibi bırak
            if (!match) return line;

            const exportPart = match[0];
            const targetColumn = exportPadStart || 90;

            // 2. Export'u satırdan geçici olarak söküp al
            // replace sadece ilk eşleşmeyi siler, bu tam istediğimiz şey.
            let leftSide = line.replace(exportPart, "");

            // Sildikten sonra sonda kalan gereksiz boşlukları temizle
            // ÖNEMLİ: trim() değil trimEnd() kullanıyoruz ki baştaki girinti (indent) bozulmasın.
            leftSide = leftSide.trimEnd();

            // 3. Mesafe Hesabı (Hedef: 70. Karakter)
            const currentLength = leftSide.length;

            // Hedefe ulaşmak için kaç boşluk lazım?
            let paddingCount = targetColumn - currentLength - exportPart.length;

            // Eğer satır zaten 70'i geçtiyse veya çok yakınsa (çakışmaması için) en az 1 boşluk bırak
            if (paddingCount < 1) {
                paddingCount = 1;
            }

            // 4. Birleştir: Sol Taraf + Boşluklar + Export
            return `${leftSide}${" ".repeat(paddingCount)}${exportPart}`;
        }).join("\n");
    };

    watContent = alignIndents(watContent);
    watContent = alignGlobals(watContent);
    watContent = alignImports(watContent);
    watContent = alignImportItemsPerfectly(watContent);
    watContent = formatWatNearPerfectRestored(watContent);
    watContent = alignExportsRight(watContent);

    return watContent;
}