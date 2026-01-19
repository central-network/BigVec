export default function (wat) {
    wat = wat.replaceAll("(malloc ", "(i32.atomic.rmw.add (i32.const 4) ")

    return wat;
}