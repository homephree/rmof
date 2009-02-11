
require File.join(File.dirname(__FILE__), 'typesafety') 

require File.join(File.dirname(__FILE__), 'typesafety_testcases') 

include TestClasses
require 'pp'

association [:pack, Pack, {:cardinality=>1}], [:cards, Card, {:cardinality=>52}]
cards=[]
(1..52).each{ cards<< Card.new}
pack= [Pack.new]  
pack.each{|p| p.cards=cards}
cards.each{|c| c.pack=pack}
pack.each{|p| p.__complete}
cards.each{|p| p.__complete}
puts pack[0].__complete.report_typesafety_errors
cards= cards[0..50]
puts cards.length
pack.each{|p| p.cards=cards}
puts pack[0].cards.length
puts pack[0].__complete.report_typesafety_errors
