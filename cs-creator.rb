#!/usr/bin/env ruby
#
# Chord Sheet Creator
# -------------------
#
# Tool for creating chord sheets for musicians
#
# Author:  Matthias Kistler <github@snoopysalive.de>
# Date:    2015-01-27
# Version: 0.1

require 'yaml'
require 'pdfkit'

class ChordSheetCreator
  
  TEMPLATE = <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>@TITLE@</title>
  <style type="text/css">
  * {
    font-family:"HelveticaNeue-Light";
  }
  table {
    font-size:12pt;
    border-spacing:0;
    margin-top:20px;
  }
  table td {
    width:@BAR-WIDTH@px;
    height:10px;
    padding:0;
  }
  table tr:first-child td {
    border-bottom:1px solid black;
  }
  table td.bar-start {
    border-bottom:0 !important;
  }
  table td.bar-begin {
    border-left:1px solid black;
    border-bottom:0 !important;
  }
  table td.bar-end {
    border-left:1px solid black;
    border-bottom:0 !important;
  }
  table td.bar-limiter {
    width:3px;
    border-right:1px solid black;
  }
  table td.bar-repeat {
    font-size:5pt;
    padding-left:1px;
    width:3px;
  }
  table td.bar-finish {
    border-left:1px solid black;
    border-right:3px solid black;
    border-bottom:0 !important;
    width:1px;
  }
  table td.bar-signature {
    border-right:0 !important;
    width:auto;
    font-size:8pt;
    padding-left:3px;
  }
  .chord {
    position:absolute;
    width:@BAR-WIDTH@px;
    margin-top:-15px;
    text-align:center;
  }
  .info {
    position:absolute;
    margin-top:-18px;
    text-align:center;
    font-size:8pt;
    margin-left:-2px;
  }
  .sup {
    position:absolute;
    margin-top:-5px;
    font-size:8pt;
  }
  </style>
</head>
<body>
  <h2>@TITLE@</h2>
  @CONTENT@
</body>
</html>
EOF
  
  def initialize(file_path)
    @config      = YAML.load_file file_path
    @line_length = @config['config']['line_length'] || 12
    reset_line
  end
  
  def to_html
    TEMPLATE.
      gsub('@TITLE@', @config['title'] || '').
      gsub('@BAR-WIDTH@', (@config['config']['bar_width'] || 40).to_s).
      sub('@CONTENT@', process_content)
  end
  
  def to_pdf
    html = to_html
    kit  = PDFKit.new html, page_size: 'A4'
    kit.to_pdf
  end

  
private

  def process_content
    content = []
    
    @config['song'].each do |title,lines|
      reset_line
      content << part_title(title)
      lines.each do |chord|
        if chord.kind_of? Array
          chord.each{|c| add_bar c}
          @line.linebreak
        else
          add_bar chord
        end
      end
      content << @line.to_s(lines == @config['song'].to_a.last[1])
    end
    
    content.join("\n")
  end
  
  def add_bar(bar)
    bar = bar.to_a[0]
    
    case bar[0]
    when ':' then @line.end_line_with_repetition bar[1]
    else @line.add_chord name:bar[0], length:bar[1]
    end
  end
  
  def part_title(title)
    parts = title.split('\\n').map do |part| 
      case part
      when '' then '<br>'
      else "<h4>#{part}</h4>"
      end
    end
    parts.join("\n")
  end
  
  def reset_line
    @line = ChordSheetLine.new length: (@config['config']['line_length'] || 12), time_signature: (@config['config']['time_signature'] || '4/4')
  end
  
end


class ChordSheetLine
  
  attr_reader :upper, :lower, :length
  
  def initialize(length: 12, time_signature: '4/4')
    @sig_upper, @sig_lower = time_signature.split '/'
    @upper     = []
    @lower     = []
    @length    = length
    @linebreak = false
    @content   = []
  end
  
  def add_chord(name: '', length: 1)
    if @linebreak or @upper.length >= @length
      @content << flatten(@upper, @lower, first: @content.length == 0)
      @upper = [] 
      @lower = []
      @linebreak = false
    end
    
    @upper << ((name != '') ? "<td><span class=\"chord\">#{normalize_chord name}</span></td>" : '<td></td>')
    @lower << '<td></td>'
    
    0.upto(length-2) do
      if @upper.length >= @length
        @content << flatten(@upper, @lower, first: @content.length == 0)
        @upper = [] 
        @lower = []
      end
      
      @upper << '<td></td>'
      @lower << '<td></td>'
    end
  end
  
  def end_line_with_repetition(repeat=1)
    @content << flatten(@upper, @lower, repeat:repeat)
    @upper = []
    @lower = []
  end
  
  def linebreak
    @linebreak = true
  end
  
  def to_s(finish=false)
    if @content.length == 0
      @content << flatten(@upper, @lower, first: true, last: true, finish: finish)
      @upper = []
      @lower = []
    elsif @upper.length != 0
      @content << flatten(@upper, @lower, last: true, finish: finish)
      @upper = []
      @lower = []
    end
    @content.join("\n")
  end
  
private

  def normalize_chord(chord)
    chord.gsub('#', '<span class="sup">#</span>&nbsp;').sub(/(&nbsp;)+$/, '')
  end

  def bar_limiter
    '<td class="bar-limiter"></td>'
  end
  
  def bar_start
    '<td class="bar-limiter bar-start"></td>'
  end

  def bar_begin
    '<td class="bar-limiter bar-begin"></td>'
  end
  
  def bar_end
    '<td class="bar-limiter bar-end"></td>'
  end
  
  def bar_repeat(repetition=1)
    '<td class="bar-limiter bar-end bar-repeat">' +
    (repetition != 1 ? "<span class=\"info\">#{repetition}x</span>" : '') +
    '•</td>'
  end
  
  def bar_finish
    '<td class="bar-limiter bar-finish"></td>'
  end
  
  def bar_signature(signature)
    "<td class=\"bar-signature\">#{signature}</td>"
  end
  
  def flatten(upper, lower, first: false, last: false, repeat: 0, finish: false)
    "<table>\n" +
    "<tr>\n#{first ? bar_begin : bar_start}\n#{bar_signature(@sig_upper)}\n#{upper.join("\n#{bar_limiter}\n")}\n#{finish ? bar_finish : (last ? bar_end : (repeat != 0 ? bar_repeat(repeat) : bar_limiter))}\n</tr>\n" +
    "<tr>\n#{first ? bar_begin : bar_start}\n#{bar_signature(@sig_lower)}\n#{lower.join("\n#{bar_limiter}\n")}\n#{finish ? bar_finish : (last ? bar_end : (repeat != 0 ? bar_repeat         : bar_limiter))}\n</tr>\n" +
    "</table>"
  end
  
end


cs = ChordSheetCreator.new ARGV[0]
puts cs.to_pdf