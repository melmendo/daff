// -*- mode:java; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

#if !TOPLEVEL
package coopy;
#end

/**
 *
 * Decorate a diff being displayed on a console.  Colors, glyphs, any
 * other eye-candy we like.
 *
 */
class TerminalDiffRender {
    private var codes: Map<String,String>;
    private var t: Table;
    private var csv: Csv;
    private var v: View;
    private var align_columns : Bool;

    public function new() {
        align_columns = true;
    }


    /**
     *
     * @param enable choose whether columns should be aligned by padding
     *
     */
    public function alignColumns(enable: Bool) {
        align_columns = enable;
    }

    /**
     *
     * Generate a string with appropriate ANSI colors for a given diff.
     *
     * @param t a tabular diff (perhaps generated by `TableDiff.hilite`)
     * @return the diff in text form, with inserted color codes
     *
     */
    public function render(t: Table) : String {
        csv  = new Csv();
        var result: String = "";
        var w : Int = t.width;
        var h : Int = t.height;
        var txt : String = "";
        this.t = t;
        v = t.getCellView();

        codes = new Map<String,String>();
        codes.set("header","\x1b[0;1m");
        codes.set("spec","\x1b[35;1m");
        codes.set("add","\x1b[32;1m");
        codes.set("conflict","\x1b[33;1m");
        codes.set("modify","\x1b[34;1m");
        codes.set("remove","\x1b[31;1m");
        codes.set("minor","\x1b[2m");
        codes.set("done","\x1b[0m");

        var sizes = null;
        if (align_columns) sizes = pickSizes(t);

        for (y in 0...h) {
            for (x in 0...w) {
                if (x>0) {
                    txt += codes["minor"] + "," + codes["done"];
                }
                txt += getText(x,y,true);
                if (sizes!=null) {
                    var bit = getText(x,y,false);
                    for (i in 0...(sizes[x]-bit.length)) {
                        txt += " ";
                    }
                }
            }
            txt += "\r\n";
        }
        this.t = null;
        v = null;
        csv = null;
        codes = null;
        return txt;
    }

    private function getText(x: Int, y: Int, color: Bool) : String {
        var val : Dynamic = t.getCell(x,y);
        var cell = DiffRender.renderCell(t,v,x,y);
        if (color) {
            var code = null;
            if (cell.category!=null) {
                code = codes[cell.category];
            }
            if (cell.category_given_tr!=null) {
                var code_tr = codes[cell.category_given_tr];
                if (code_tr!=null) code = code_tr;
            }
            if (code!=null) {
                if (cell.rvalue!=null) {
                    val = codes["remove"] + cell.lvalue + codes["modify"] + cell.pretty_separator + codes["add"] + cell.rvalue + codes["done"];
                    if (cell.pvalue!=null) {
                        val = codes["conflict"] + cell.pvalue + codes["modify"] + cell.pretty_separator + val;
                    }
                } else {
                    val = cell.pretty_value;
                    val = code + val + codes["done"];
                }
            }
        } else {
            val = cell.pretty_value;
        }
        return csv.renderCell(v,val);
    }

    private function pickSizes(t: Table) {
        var w : Int = t.width;
        var h : Int = t.height;
        var v : View = t.getCellView();
        var csv  = new Csv();
        var sizes = new Array<Int>();
        var row = -1;
        var total = w-1; // account for commas
        for (x in 0...w) {
            var m : Float = 0;
            var m2 : Float = 0;
            var mmax : Int = 0;
            var mmostmax : Int = 0;
            var mmin : Int = -1;
            for (y in 0...h) {
                var txt = getText(x,y,false);
                if (txt=="@@"&&row==-1) {
                    row = y;
                }
                var len = txt.length;
                if (y==row) {
                    mmin = len;
                }
                m += len;
                m2 += len*len;
                if (len>mmax) mmax = len;
            }
            var mean = m/h;
            var stddev = Math.sqrt((m2/h)-mean*mean);
            var most = Std.int(mean+stddev*2+0.5);
            for (y in 0...h) {
                var txt = getText(x,y,false);
                var len = txt.length;
                if (len<=most) {
                    if (len>mmostmax) mmostmax = len;
                }
            }
            var full = mmax;
            most = mmostmax;
            if (mmin!=-1) {
                if (most<mmin) most = mmin;
            }
            sizes.push(most);
            total += most;
        }
        if (total>130) {  // arbitrary wide terminal size
            return null;
        }
        return sizes;
    }
}
