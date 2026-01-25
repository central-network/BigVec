cd 01-text
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 02-include
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 03-ref.extern
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 04-ref.func
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 05-global.get
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 06-async
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 07-data
wat4wasm --input=module.wat --output=module-output.wat --wat2wasm=wat2wasm
cd ..

cd 08-reflectors
wat4wasm --input=module.wat --output=module-output.wat
cd ..

cd 09-replaceAll
wat4wasm --input=module.wat --output=module-output.wat
cd ..


cd 99-complex
wat4wasm --input=module.wat --output=output.html --wat2wasm=wat2wasm --keep-window --keep-chrome-global --keep-document --wasm-from-numbers-array --log-instance --debug-names --enable-threads --apply=apply_1.js
cd ..
