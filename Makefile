
console: typesafty_console.rb
	ruby typesafty_console.rb

result : typesafety_test.rb
	ruby typesafety_basic_test.rb
	ruby typesafety_test.rb

tags : *.rb 
	ctags -R *.rb

clean :
	rm tags
	rm tmp/*
	rmdir tmp
