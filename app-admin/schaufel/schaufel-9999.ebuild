# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user git-r3

DESCRIPTION="shovel data around"
HOMEPAGE="https://github.com/adjust/schaufel"
EGIT_REPO_URI="https://github.com/adjust/schaufel.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
>=dev-libs/librdkafka-0.9.4[lz4]
dev-libs/hiredis
dev-db/postgresql
"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 /var/lib/${PN} ${PN}
}

src_install() {
	emake PREFIX="${D}" install
	insinto /usr/bin
	doins "${D}/${PN}"
	fperms +x /usr/bin/${PN}
	newconfd "${FILESDIR}/${PN}.confd" ${PN}
	newinitd "${FILESDIR}/${PN}.initd" ${PN}
	diropts -m 0755 -o ${PN} -g ${PN}
	keepdir /var/{log,lib}/${PN}
}
