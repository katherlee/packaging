require 'formula'

class Alpscore < Formula
  homepage "http://alpscore.org"
  url "alpscore"
  sha256 "b043f5043f6fdca5efd8e1fc2ba0d893da0fd04bff8adaa213c797b44d68e72e"

  # fetch current version fro git (fix with first release)
  url "https://github.com/ALPSCore/ALPSCore/archive/v0.4.5.tar.gz"

  # head version checked out from git
  head "https://github.com/ALPSCore/ALPSCore.git"

  # options
  option "with-static", "Build static instead of shared libraries"
  option "without-mpi", "Disable building with MPI support"
  option :cxx11
  option "with-doc",    "Build documentation"
  option "with-check",  "Build and run shipped tests"

  # Dependencies
  # cmake
  depends_on "cmake"   => :build
  # boost - check mpi and c++11
  boost_options = []
  boost_options << "with-mpi" if build.with? "mpi"
  boost_options << "without-single" if build.with? "mpi"
  boost_options << "c++11" if build.cxx11?
  depends_on "boost" => boost_options
  # mpi, hdf5
  if build.cxx11?
      depends_on "open-mpi" => ["c++11", :recommended] if build.with? "mpi" # boost has troubles with mpich
      depends_on "hdf5" => ["c++11"]
  else
      depends_on :mpi      => [:cc, :cxx, :recommended] if build.with?"mpi"
      depends_on "hdf5"
  end

  def install
      args = std_cmake_args
      # force release mode (taken from eigen formula)
      args.delete "-DCMAKE_BUILD_TYPE=None"
      args << "-DCMAKE_BUILD_TYPE=Release"
      # handle static/shared build
      if build.with?"static"
          args << "-DBuildStatic=ON"
          args << "-DBuildShared=OFF"
      else
          args << "-DBuildStatic=OFF"
          args << "-DBuildShared=ON"
      end

      # check python compilation only with shared mode
      if build.with?"static" and build.with?"python"
          raise <<-EOS.undent
              Build python requires building shared libraries. Use "--without-static".
          EOS
      end

      # handle mpi
      if build.with?"mpi"
         args << "-DENABLE_MPI=ON"
      else
         args << "-DENABLE_MPI=OFF"
      end

      # documentation
      if build.with?"doc"
          args << "-DDocumentation=ON"
      else
          args << "-DDocumentation=OFF"
      end

      # check
      if build.with?"check"
          args << "-DTesting=ON"
          args << "-DTestXMLOutput=TRUE"
      else
          args << "-DTesting=OFF"
      end

      # do the actual install
      mkdir "tmp"
      chdir "tmp"
      # the source is at parent dir
      args << ".."
      system "cmake", *args
      if build.with?"check"
         system "make"
         system "make", "test"
      end
      system "make", "install"
  end

      # Testing
  test do
    # here we need an external test - probably best t
    (testpath/"test.cpp").write <<-EOS.undent
      #include <alps/mc/api.hpp>
      #include <alps/mc/mcbase.hpp>
      #include <alps/accumulators.hpp>
      using namespace std;

      int main()
      {
        alps::accumulators::accumulator_set set;
        set << alps::accumulators::FullBinningAccumulator<double>("a");
        set["a"] << 2.9 << 3.1;
      }
    EOS
    args_compile = %W[]
    args_compile << "test.cpp" << "-lalps-accumulators" << "-lalps-hdf5" << "-lalps-utilities"
    args_compile << "-lboost_filesystem-mt" << "-lboost_system-mt" << "-lboost_program_options-mt"
    if build.with?"mpi"
        args_compile << "-lmpi" << "-lmpi_cxx" << "-lboost_mpi-mt"
    end
    args_compile << "-o" << "test"
    #system ENV.cxx, "test.cpp", "-lalps-accumulators", "-lalps-hdf5", "-lalps-accumulators", ["-lmpi" if build.with?"mpi"],"-o", "test"
    system ENV.cxx, *args_compile
    system "./test"

  end
end
