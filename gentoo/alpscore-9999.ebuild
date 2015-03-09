# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MY_PN="ALPSCore"

PYTHON_COMPAT=( python{2_5,2_6,2_7} )

inherit cmake-utils python-r1

if [[ ${PV} == "9999" ]]; then
    EGIT_REPO_URI="https://github.com/${MY_PN}/${MY_PN}.git"
    inherit git-r3
fi

DESCRIPTION="Algorithms and Libraries for Physics Simulations - core library"
HOMEPAGE="http://alpscore.org/"

LICENSE="GPL2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="python tutorials mpi doc tutorials test"

DEPEND=">=dev-libs/boost-1.47.0[mpi?,python?]
    >=sci-libs/hdf5-1.8.2 
    python? ( 
        ${PYTHON_DEPS}
        dev-python/numpy
    )
    mpi? ( virtual/mpi )
    doc? ( app-doc/doxygen )"
RDEPEND="${DEPEND}"

src_configure() {
    mycmakeargs="
        $(cmake-utils_use python BuildPython)
        $(cmake-utils_use doc Documentation)
        $(cmake-utils_use tutorials BuildTutorials)
        $(cmake-utils_use test Testing)
        $(cmake-utils_use mpi ENABLE_MPI)
        "
    python_foreach_impl cmake-utils_src_configure
}

src_compile()
{
    python_foreach_impl cmake-utils_src_compile
}

src_install()
{
    python_foreach_impl cmake-utils_src_install
}
