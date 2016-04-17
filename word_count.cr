# use SHELL cmd (linux) to tie a process to a CPU
# then run multiple copies (tied to different CPUs)
# i.e. taskset -cp <core> <pid>
#
# e.g.
#  taskset -cp 0 <pid> # tie this pid to core 0
#  taskset -cp 2 <pid> # tie this pid to core 1
#  taskset -cp 3 <pid> # tie this pid to core 2

# crystal build --release word_count.cr
# ./word_count ./word_count.cr
class WordCount
  def initialize(filename="")
    @filename = filename || ""
    puts("Unknown file: %s" % @filename) unless File.exists?(@filename)

    @results = {"word" => 0}
    @results.delete("word")
    count_words
  end

  def print_counts
    @results.to_a.sort{ |a, b| b.last <=> a.last }.each do |ary|
      word, count = ary
      puts "%d, %s" % [count, word]
    end
  end


  private def count_words
    return unless File.exists?(@filename)
    File.open(@filename, "r") do |f|
      f.each_line do |l|
        l.split().each do |w|
          @results[w] ||= 0
          @results[w] += 1
        end
      end
    end
  end
end

filename = (ARGV[0] || "").to_s
wc = WordCount.new(filename)
wc.print_counts
