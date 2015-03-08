# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Alpscore < Formula
  homepage "http://alpscore.org"
  url "alpscore"
  sha256 ""
  version "0.2"

  # fetch current version fro git (fix with first release)
  url "https://github.com/ALPSCore/ALPSCore.git", :using => :git, :tag => "master"

  # head version checked out from git
  head "https://github.com/ALPSCore/ALPSCore.git"

  # options
  option "with-python", "Build python module"
  option "with-static", "Disable building static library variant"
  option "with-mpi", "Build with MPI support"
  option :cxx11
  option "with-doc", "Build Documentation"

  # Dependencies
  # cmake
  depends_on "cmake"   => :build
  # python
  depends_on "python"  => [:optional] if build.with?"python"
  # c++11
  if build.cxx11?
      depends_on "open-mpi" => "c++11" if build.with? "mpi" # boost has troubles with mpich
      depends_on "boost" => [:required, "with-c++11"]
      depends_on "boost" => [:required, "with-c++11", "with-mpi"] if build.with?"mpi"
      depends_on "boost-python" => [:optional, "with-c++11"] if build.with?"python"
      depends_on "hdf5" => [:required, "with-c++11"]
  else
      depends_on :mpi      => [:cc, :cxx, :optional] if build.with?"mpi"
      depends_on "boost"   => :required 
      depends_on "boost" => [:required, "with-mpi"] if build.with?"mpi"
      depends_on "boost-python" => [:optional] if build.with?"python"
      depends_on "hdf5"    => :required
  end

  args = []
  # handle static/shared build
  if build.with?"static"
      args << "-DEnableStatic=ON"
      args << "-DEnableShared=OFF"
  else
      args << "-DEnableStatic=OFF"
      args << "-DEnableShared=ON"
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

  # handle python
  if build.with?"python"
      args << "BuildPython=ON"
  else
      args << "BuildPython=OFF"
  end

  # documentation
  if build.with?"doc"
      args << "BuildDocumentation=ON"
  else
      args << "BuildDocumentation=OFF"
  end

  # tutorials
  if build.with?"tutorials"
      args << "BuildTutorials=ON"
  else
      args << "BuildTutorials=OFF"
  end

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    system "cmake", ".", *std_cmake_args, *args
    system "make", "install" 
  end

  # Testing
  test do
      system "make", "test" # if this fails, try separate make/make install steps
  end
end
