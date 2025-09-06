local fs=require("@lune/fs")

for _,v in fs.readDir("./src") do
    pcall(fs.removeFile,`./src/{v}`)
    pcall(fs.removeDir,`./src/{v}`)
end